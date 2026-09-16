---
title: 'Fix the edit-page Delete Event link'
type: 'bugfix'
created: '2026-09-16'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
baseline_commit: 'b15755d70af82fe1a93ce278d0f3a5b08773e974'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The "Delete Event" control on the event edit page is `link_to ... method: :delete, data: { confirm: }`, which is rails-ujs syntax. rails-ujs isn't loaded (Turbo/Stimulus only), so clicking it sends a plain `GET /events/:id`. There's no show view, so the owner hits an error page, nothing is deleted, and no confirmation appears.

**Approach:** Replace it with a `button_to` that submits a real DELETE form to `EventsController#destroy`, carrying the confirmation as Turbo's `turbo_confirm` with the message unchanged. This matches the events index's working Delete button, and because it's a real form it works without JavaScript and can be tested without a browser.

## Boundaries & Constraints

**Always:** Keep the confirmation text exactly "Are you sure you want to delete this event?". Keep the control visually the same small red text link in the same spot. Deletion goes through `EventsController#destroy`, so the dashboard redirect, notice, and cancellation notifications still happen.

**Never:** Don't add an `events/show` view or route change. Don't reinstall rails-ujs or add JavaScript. Don't touch any other confirm in the app — the other 40 are Story 2.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Delete confirmed | Owner on edit page clicks Delete Event, accepts prompt | `DELETE /events/:id`; event removed; redirect to dashboard with "Event was successfully destroyed." | N/A |
| Delete dismissed (browser only) | Owner clicks Delete Event, dismisses prompt | No request sent; still on edit page; event exists | Manual check — rack_test ignores `data-turbo-confirm` |
| No JavaScript | Form submitted without Turbo | Still deletes and redirects (real form POST with `_method=delete`) | N/A |

</frozen-after-approval>

## Code Map

- `app/views/events/edit.html.erb:13` -- the broken `link_to ... method: :delete`; the only production file to change
- `turbo-rails 2.0.11` `turbo.js:962` -- reads `data-turbo-confirm` from the submitter button first, then the form, so the confirm belongs on the `button_to` itself
- `app/models/event.rb` `notify_members_of_deletion` -- `after_destroy` enqueues `EventDeletionNotificationJob` and `EventDeletionEmailNotificationJob`; test env uses the `:test` job adapter (`spec/rails_helper.rb`), so they only enqueue
- `app/views/events/index.html.erb:115` -- working `button_to ... method: :delete` to mirror (its own `data: { confirm: }` stays for Story 2)
- `app/controllers/events_controller.rb#destroy` -- already redirects to `dashboard_path` with the notice for html and turbo_stream; do not change
- `spec/factories/lounge_owners.rb` -- `:with_subscription` trait passes `check_subscription`; feature specs use Devise `sign_in`
- `spec/features/rsvp_dashboard_integration_spec.rb` -- existing signed-in feature spec pattern to follow

## Tasks & Acceptance

**Execution:**
- [x] `app/views/events/edit.html.erb` -- replace the `link_to` with `button_to 'Delete Event', event_path(@event), method: :delete, data: { turbo_confirm: 'Are you sure you want to delete this event?' }, class: <same class string as today>`; no `form:` class needed (Tailwind preflight already strips button chrome, and the form sits inside the existing `mt-5` div) -- a real DELETE form is what actually reaches `destroy`
- [x] `spec/features/event_delete_from_edit_page_spec.rb` -- new feature spec (rack_test) using `:with_subscription` and `sign_in`, covering the acceptance criteria below -- covers the non-browser matrix rows

**Acceptance Criteria:**
- Given a subscribed owner on an event's edit page, when they click "Delete Event", then `Event.count` drops by 1, `Event.exists?(event.id)` is false, `current_path` is `dashboard_path`, and the page shows "Event was successfully destroyed."
- Given the same click, then `EventDeletionNotificationJob` and `EventDeletionEmailNotificationJob` are enqueued, proving deletion ran through the model's `after_destroy`.
- Given the rendered edit page, when inspecting the Delete Event button, then it carries `data-turbo-confirm="Are you sure you want to delete this event?"`.

## Verification

**Commands:**
- `bundle exec rspec spec/features/event_delete_from_edit_page_spec.rb spec/models/event_spec.rb` -- expected: all pass
- `bundle exec rspec` -- expected: no new failures beyond the known `subscription_flow_spec.rb` ones

**Manual checks (if no CLI):**
- In the browser: edit page → Delete Event → prompt appears → Cancel leaves the event; OK deletes it and lands on the dashboard with the notice.

## Known Issues (out of scope)

- `EventsController`, `MembershipsController`, and `SpecialOffersController` load records with bare `find(params[:id])` and no ownership check, so any subscribed owner can edit or delete another lounge's records. Pre-existing; not changed by this story.

## Implementation Notes

- `edit.html.erb:13`: `link_to ... method: :delete, data: { confirm: }` → `button_to 'Delete Event', event_path(@event), method: :delete, data: { turbo_confirm: }`, same class string and wrapper. No other production files changed.
- New `spec/features/event_delete_from_edit_page_spec.rb` (rack_test): asserts the `data-turbo-confirm` attribute and exact text, the delete (count -1, `Event.exists?` false, dashboard path, notice), and both deletion jobs enqueued. All 3 examples fail with the view change reverted.
- Verification: target specs 51 examples, 0 failures; full suite 364 examples, 3 failures — the known `subscription_flow_spec.rb` ones.
- Matrix audit: "Delete confirmed" and "No JavaScript" are covered by the rack_test spec. "Delete dismissed" has no automated test — no Chrome/chromedriver on this machine for a `js: true` spec — so it stays the manual browser check the spec approved. Rendered styling of the button is also unverified in a browser.

## Spec Change Log

## Review Triage Log

- **low, patch** — (edge-case + blind hunter) job-enqueue scenario checks only job classes; no active membership so `member_ids` is always `[]` and a bad `event_data` payload would pass. Patched: membership created, `.with(hash_including(...))` on both matchers.
- **low, patch** — (blind hunter) `clear_enqueued_jobs` is a no-op; block-form `have_enqueued_job` only counts jobs enqueued in the block. Patched: removed.
- **high, defer** — (edge-case + blind hunter) `EventsController#set_event` uses unscoped `Event.find`, so any subscribed owner can delete another lounge's event. Pre-existing: the index Delete button already reached `destroy`. Logged; ownership-scoping spec follows these stories.
- **medium, defer** — (edge-case + blind hunter) no automated test for dismissing the prompt. Needs a `js: true` spec; no Chrome/chromedriver locally and no CI. The approved matrix makes it a manual check.
- **false** — (edge-case) `@event.destroy` returning false would show a success notice. No `before_destroy`/`throw(:abort)` on `Event`, `Rsvp`, or `EventRegistration`; `dependent: :destroy` only, so destroy can't return false here.
- **low, rejected** — (edge-case + blind hunter) second DELETE on an already-deleted event raises `RecordNotFound` → 404. Pre-existing (same for the index button), rare since Turbo disables the button in flight, and the fix adds a rescue guard.
- **false** — (blind hunter) confirm test only checks markup, so a GET form or wrong-event form would pass. The click scenario would fail: it asserts that event is destroyed and the dashboard redirect.
- **false** — (blind hunter) no guard against `link_to` coming back. Restoring it removes the `<button>`, failing both the `have_css('button[...]')` and `click_button` scenarios.
- **maybe-false, rejected** — (blind hunter) rendered look unverified. Would settle with a browser look; if wrong it's only cosmetic (low), and it's part of the user's manual check.
- **false** — (blind hunter) missing focus style "unlike the Back link". Neither the old Delete link nor the Back link has a `focus-visible:` class (base b15755d); not a regression.
- **low, rejected** — (blind hunter) index page Delete button still uses dead `data: { confirm: }`. Out of scope by intent ("don't touch any other confirm"); it's Story 2.
- **low, rejected** — (blind hunter) missing trailing newline in `edit.html.erb`. Pre-existing at b15755d; cosmetic.
