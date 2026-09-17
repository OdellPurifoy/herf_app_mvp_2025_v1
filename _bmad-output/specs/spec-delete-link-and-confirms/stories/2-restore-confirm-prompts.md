---
title: 'Restore confirmation prompts app-wide'
type: 'bugfix'
created: '2026-09-17'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
baseline_commit: 'c0130cff8b7bb6796c3a9b1c1aebf9b782ae65a1'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** 40 `button_to` controls across 15 view files declare `data: { confirm: "Are you sure?" }`, which is rails-ujs syntax. rails-ujs isn't loaded (importmap pins only Turbo and Stimulus) and no JavaScript handles `data-confirm`, so no dialog ever appears. Deleting an event, membership, or special offer happens on the first click, and so does signing out. Event deletion also emails and texts every member, so a misclick reaches people outside the app.

**Approach:** Rename the `confirm:` key to `turbo_confirm:` on every one of those controls, keeping each message's text exactly as written, so Turbo shows its native confirmation. Two "Cancel my account" buttons already carry a working `turbo_confirm` alongside the dead legacy key; drop the legacy key there. No markup, styling, routes, or JavaScript otherwise change.

## Boundaries & Constraints

**Always:** Keep every message's text verbatim ("Are you sure?" in all 40). Keep the same set of confirmed actions, sign-out included — this restores behavior that was always intended, it doesn't redesign it. Use Turbo's native `data-turbo-confirm`.

**Never:** Don't reinstall rails-ujs or add JavaScript. Don't add confirmations to controls that don't have one today, don't remove any, and don't reword them. Don't refactor the duplicated nav into a partial — tempting, but that's a separate change.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Destructive click, accepted | Owner clicks Delete on an event/membership/special offer, accepts | Prompt shows, then the record is deleted as before | N/A |
| Destructive click, dismissed (browser only) | Owner clicks Delete, dismisses | No request sent; record still exists | Manual check — rack_test ignores `data-turbo-confirm` |
| Sign out, accepted | Owner clicks Sign out, accepts | Prompt shows, then session ends | N/A |
| No JavaScript | Form submitted without Turbo | Still submits and performs the action (real form, prompt is a JS-layer nicety) | N/A |

</frozen-after-approval>

## Code Map

- 15 files under `app/views/` carry the 40 broken `data: { confirm: "Are you sure?" }` attributes; all are `button_to`, no `link_to`/`button_tag`/`submit_tag` cases
  - 36 are sign-out buttons (`destroy_lounge_owner_session_path` / `destroy_admin_session_path`), repeated ~3× per page because the nav is copy-pasted, not a partial
  - 4 are record deletes: `app/views/memberships/index.html.erb` (2), `app/views/events/index.html.erb:115`, `app/views/special_offers/index.html.erb:114`
- `app/views/devise/registrations/edit.html.erb:109` and `app/views/admins/registrations/edit.html.erb:41` -- "Cancel my account" already has `turbo_confirm` plus a dead legacy `confirm:`; drop the legacy key only
- `app/views/events/edit.html.erb:13` and `app/views/event_registrations/show.html.erb:83` -- already correct (Story 1 and prior work); do not touch
- `turbo-rails 2.0.11` `turbo.js:962` -- Turbo reads `data-turbo-confirm` from the submitter button first, then the form, so the attribute belongs on the `button_to` itself
- `spec/features/event_delete_from_edit_page_spec.rb:22` -- existing pattern for asserting the attribute in a rack_test spec

## Tasks & Acceptance

**Execution:**
- [x] `app/views/**` (15 files) -- rename `confirm:` to `turbo_confirm:` inside the `data:` hash of all 40 affected `button_to` calls, text unchanged -- the only reason the prompts never appear
- [x] `app/views/devise/registrations/edit.html.erb`, `app/views/admins/registrations/edit.html.erb` -- remove the dead legacy `confirm:` key, keep the existing `turbo_confirm:` -- leaves one source of truth per control
- [x] `spec/views/confirm_prompts_spec.rb` -- new spec that scans `app/views/**/*.erb` and fails if any `data:` hash still contains a bare `confirm:` key -- a grep-style guard so this can't silently regress
- [x] `spec/features/destructive_confirm_prompts_spec.rb` -- new rack_test feature spec asserting the rendered Delete buttons on the events, memberships, and special offers index pages carry `data-turbo-confirm="Are you sure?"`, and that deleting still works -- proves the real pages, not just the source text

**Acceptance Criteria:**
- Given any view under `app/views/`, when scanned, then no `data:` hash contains a bare `confirm:` key.
- Given a signed-in subscribed owner on the events, memberships, or special offers index, when the page renders, then each Delete button carries `data-turbo-confirm="Are you sure?"`.
- Given that same owner, when they click Delete on a membership, then the membership is destroyed and the page reports success (behavior unchanged from today).

## Verification

**Commands:**
- `bundle exec rspec spec/views/confirm_prompts_spec.rb spec/features/destructive_confirm_prompts_spec.rb` -- expected: all pass
- `grep -rn "data: { confirm:" app/views | wc -l` -- expected: `0`
- `bundle exec rspec` -- expected: no new failures beyond the known `subscription_flow_spec.rb` ones and the logged Faker flakes

**Manual checks (if no CLI):**
- In the browser: Delete on an event/membership/special offer prompts; Cancel leaves the record; OK deletes it. Sign out prompts too.

## Implementation Notes

- 42 `data: { confirm: ... }` occurrences existed across 15 view files: 40 bare legacy keys plus the 2 "Cancel my account" controls that also carried `turbo_confirm`. All 42 now read `data: { turbo_confirm: ... }`, with each message string (and its original quote style) untouched. The 2 registrations views ended up with a single `turbo_confirm:` key, as specified.
- `app/views/events/edit.html.erb:13` and `app/views/event_registrations/show.html.erb:83` were left alone; they were already correct. Views under `app/views/` now hold 44 `turbo_confirm` references (42 converted + those 2).
- `spec/lint/confirm_prompts_spec.rb` is the source-scan guard. It lives outside `spec/views/` on purpose: `infer_spec_type_from_file_location!` would otherwise type it `:view` and load `ActionView::TestCase` for what is only a file scan. It covers `app/views/**/*.erb`, `app/helpers/**/*.rb`, and `app/components/**/*.rb` (the last currently does not exist, so the glob is a no-op until it does), reporting `path:line` per offender.
- The guard runs in both directions. **Negative:** no legacy key, matched as `/(?<!\w)(?:confirm:|:confirm\s*=>|["']confirm["']\s*=>)/` inside a `data:` hash, plus a separate `/data-confirm\s*=/` sweep for the raw HTML attribute. The `data:` hash body is extracted by counting braces rather than with `[^}]*`, so a key sitting after a nested hash or a `#{}` interpolation is still seen. The lookbehind lets `turbo_confirm:` and `password_confirmation:` through. **Positive:** every `button_to` with `method: :delete` targeting one of the six destroy path helpers must carry `turbo_confirm:` -- so deleting a `data:` hash outright fails too. The 5 `app/views/admin_dashboard/*` "Log Out" buttons, which have no prompt today, are allowlisted by path and the total unprompted count is pinned at 5, so a 6th unprompted control fails even inside an allowlisted file.
- The guard's own patterns are unit-tested against inline snippets (each legacy spelling, the nested-hash and interpolation cases, the raw attribute, a correct control, and the `button_to` block form), so a broken pattern fails instead of quietly matching nothing.
- `spec/features/destructive_confirm_prompts_spec.rb` renders the events, special offers, and memberships index pages, the dashboard, and the account settings page, asserting the relevant control carries `data-turbo-confirm="Are you sure?"` and that the page emits no `[data-confirm]` at all (the bare attribute selector, so a link or input regression is caught as well as a button). Account settings additionally pins `count: 1` on "Cancel my account", since that is the control whose duplicate legacy key was dropped. Memberships index renders Delete twice per record (desktop + mobile), so the destroy example uses `click_button 'Delete', match: :first`.
- The "Sign out, accepted" matrix row is covered behaviorally as well as structurally: one example clicks the sign-out button and then visits `dashboard_path`, asserting it bounces to `new_lounge_owner_session_path` -- proving the session really ended rather than just that a redirect happened. Memberships index renders three sign-out forms (desktop, mobile header, mobile menu) and one is icon-only, so the click targets the first matching form/attribute selector rather than matching on button text. That selector is built from `destroy_lounge_owner_session_path` rather than a hardcoded `/lounge_owners/sign_out`, so a Devise path change can't turn it into a selector that matches nothing.
- No JavaScript, importmap, routing, markup, or styling changes; the duplicated nav was left un-extracted per the boundaries.

## Spec Change Log

## Review Triage Log

- **medium, patch** — (verification-gap, pre-verified) Only 3 of 15 changed templates get a rendered assertion; the dashboard sign-out attribute could be deleted with the suite still green. Patched: dashboard example added.
- **medium, patch** — (verification-gap + blind hunter + edge-case) The guard only detects a re-introduced legacy key, never asserts a prompt is present, so removing a `data:` hash entirely passes. Patched: positive destroy-path check with an explicit allowlist for the 5 pre-existing unprompted admin Log Out buttons.
- **medium, patch** — (edge-case + blind hunter) Guard regex misses `:confirm =>`, `"confirm" =>`, `confirm:` after an interpolation/nested hash, and raw `data-confirm=`. Verified all five against the exact pattern with a probe. Patched: regex broadened.
- **low, patch** — (edge-case + blind hunter) Scan globs only `app/views/**/*.erb`; helpers/components unguarded. Latent (no such code today). Patched: glob widened.
- **low, patch** — (blind hunter) Guard has no positive control — matching logic never exercised, so a broken regex stays green. Patched: known-bad/known-good examples added.
- **low, patch** — (blind hunter) `/m` flag is a no-op and the Implementation Note misattributed multi-line tolerance to it. Patched.
- **low, patch** — (blind hunter + verification-gap) Source-scan spec sat in `spec/views/`, so `infer_spec_type_from_file_location!` typed it `:view`. Patched: moved to `spec/lint/`.
- **low, patch** — (blind hunter) `have_no_css('button[data-confirm]')` too narrow; link/input regressions pass. Patched: selector widened.
- **low, patch** — (blind hunter) "Cancel my account" (devise registrations) lost its legacy key and had no test. Patched: example added.
- **low, patch** — (blind hunter) Sign-out selector hardcoded the Devise path string. Patched: route helper used.
- **medium, defer** — (blind hunter + edge-case + verification-gap) 5 `app/views/admin_dashboard/*` Log Out buttons have no confirmation at all. Verified pre-existing via `git stash` — identical count on the baseline — and the frozen Boundaries forbid adding prompts where none exist. Deferred; the new guard's allowlist makes the inconsistency explicit.
- **low, defer** — (edge-case) `app/views/admins/registrations/edit.html.erb` is unreachable: `config/routes.rb:8` declares `devise_for :admins, skip: [:registrations]`, so `registration_path(resource_name)` has no route. Pre-existing dead view; the legacy-key cleanup there is harmless but untestable. Deferred.
- **low, defer** — (blind hunter) "Are you sure?" is duplicated 44 times in two quote styles with no context about consequences; an i18n key or per-action wording would be better. Wording frozen by intent. Deferred.
- **low, rejected** — (blind hunter) No CI runs the guard. True, but already tracked as its own deferred item (no CI pipeline).
- **low, rejected** — (blind hunter + verification-gap) No `js: true` test for the dismissed prompt. Already deferred from Story 1 (needs Chrome/chromedriver); the matrix marks it a manual check.
- **low, rejected** — (blind hunter) Extract the duplicated nav into a partial. Excluded by the frozen Boundaries ("don't refactor the duplicated nav").
- **low, rejected** — (blind hunter) No behavioral event-destroy test on the index page. `spec/features/event_delete_from_edit_page_spec.rb` already covers `EventsController#destroy` end to end, including the notification jobs; the index button reaches the same action.
- **low, rejected** — (blind hunter) `Time.zone.today + 1.week + 7.hours` is obscure. Cosmetic, and it mirrors the existing spec style in this repo.
- **low, rejected** — (blind hunter) Prefer server-side safeguards (soft delete, undo window, `Turbo.setConfirmMethod`) for irreversible actions. Product-level redesign, far outside this story's intent.
