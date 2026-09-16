---
title: 'Fix RSVP re-edit lockout after first response'
type: 'bugfix'
created: '2026-09-16'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Once a member has responded to an RSVP once (attending or declined), any later visit to the same link is rejected with "This RSVP has expired and can no longer be updated" — even when the RSVP's real `expires_at` hasn't passed. `RsvpsController#update` and the view's form (`app/views/rsvps/show.html.erb`) both gate on `Rsvp#valid_for_response?`, which requires `status == pending`, so a legitimate change of mind or guest-count update is permanently blocked after the first response.

**Approach:** Redefine `Rsvp#valid_for_response?` to mean "not expired" only (drop the `pending?` requirement), so the existing form-rendering and update-handling logic — which already reads correctly off this one method in both the controller and the view — allows re-editing any time before real expiry. Update the model's existing spec for `#valid_for_response?` to match the new contract, and add a request-level example proving a second, changed submission after an initial response succeeds while a truly expired RSVP still doesn't.

</frozen-after-approval>

## Implementation Notes

- `Rsvp#valid_for_response?` redefined from `!expired? && pending?` to `!expired?`. Added a clarifying comment so a future maintainer doesn't "restore" the `pending?` clause and reintroduce this bug.
- Simplified `RsvpsController#update`: the old code had two separate expired-checking branches (`if @rsvp.expired?` early return, then `if @rsvp.valid_for_response? ... else ...`) that became exactly equivalent once `valid_for_response?` dropped `pending?`. Collapsed to one `unless @rsvp.valid_for_response?` guard.
- `respond_with`'s own `return false if expired?` guard is now redundant with the controller's check at its only call site — kept intentionally as a model-level invariant (documented with a comment) rather than removed, since it protects any future caller that doesn't go through the controller.
- Environment note: local Postgres wasn't installed and Redis wasn't running. Installed `postgresql@16` via Homebrew and started it to run the test suite; Redis remains unavailable but wasn't needed for these specs (job/mailer specs use test adapters, not live Sidekiq).
- Full suite run for regression check: 348 examples, 35 pre-existing failures unrelated to this change (missing compiled Tailwind assets, and sidekiq-cron specs needing live Redis) — zero RSVP-related failures.
- Noticed but out of scope: `Rsvp#mark_expired_if_past_due` is dead code, and `guest_count` validation is unconditional on status. Both deferred — see `deferred-work.md`.

## Review Triage Log

- **high, deferred** — `RsvpsController#update`'s invalid-params render path never sets `@guest_count_options`, causing a `NoMethodError` in the view (`show.html.erb:144`). Verified real; pre-existing (not caused by this diff) so deferred rather than patched. See `deferred-work.md`.
- **medium, deferred** — `Rsvp#mark_expired_if_past_due`'s guard (`if expired? && !expired?`) is dead code; `status` never actually becomes `:expired`. Verified real; pre-existing and unrelated to the time-based fix here. See `deferred-work.md`.
- **medium, patched** — No test proved a guest-count-only edit (same status, new count) or the declined→attending direction, despite both being part of this story's stated capability. Added both as controller spec examples.
- **low, patched** — No test locked down behavior when `status` is `:expired` but `expires_at` is still future (time is authoritative over the status column). Added a model spec example.
- **low, patched** — No comment explained why `pending?` was intentionally dropped from `valid_for_response?`, risking silent reintroduction of the bug. Added.
- **low, false** — Reviewer suggested `respond_with`'s own `expired?` guard was pure redundant cruft; disagreed — kept intentionally as model-level defense-in-depth for future callers, now documented with a comment instead of removed.
- **low, patched** — Controller test for the declined-response case didn't assert `guest_count`; covered by the new guest-count-only test example instead of modifying the existing one.
