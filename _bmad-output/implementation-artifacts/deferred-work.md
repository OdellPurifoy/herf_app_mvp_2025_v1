- source_spec: `_bmad-output/specs/spec-rsvp-notification-fixes/stories/1-rsvp-reedit-lockout.md`
  summary: RsvpsController#update's invalid-params failure path (`render :show, status: :unprocessable_entity`) never sets `@guest_count_options`, which the show view's guest-count `<select>` requires (`@guest_count_options.map { ... }`) — raises NoMethodError on nil for any real request that submits an invalid RSVP update.
  evidence: Verified directly — `show` sets `@guest_count_options = (1..10).to_a` but `update` never does, and `app/views/rsvps/show.html.erb:144` calls `.map` on it unconditionally. Pre-existing (the render call predates this story's diff); not caused by the re-edit-lockout fix, though re-editing now reaches this path more often.

- source_spec: `_bmad-output/specs/spec-rsvp-notification-fixes/stories/1-rsvp-reedit-lockout.md`
  summary: Rsvp#mark_expired_if_past_due is dead code — `update_column(:status, :expired) if expired? && !expired?` can never be true, so the `status` column never actually becomes `:expired` and the `status_display` "Expired" branch and `Rsvp.expired` enum value are unreachable through normal app flow.
  evidence: Verified directly by reading app/models/rsvp.rb and confirming no other call site ever sets `status: :expired`. Pre-existing, unrelated to this story's fix (which is time-based via `expires_at`, not the `status` column).

- source_spec: `_bmad-output/specs/spec-rsvp-notification-fixes/stories/1-rsvp-reedit-lockout.md`
  summary: Rsvp's guest_count validation (`presence: true, numericality: { greater_than: 0 }`) is unconditional on status, so a `declined` RSVP is forced to carry a meaningless positive guest_count. User flagged this as illogical; deferred rather than fixed now.
  evidence: `total_attendees` already treats guest_count as irrelevant for non-attending RSVPs (`attending? ? guest_count : 0`), so this is a data-modeling quirk, not a functional bug — user chose to defer rather than make the validation conditional on `attending?`.
