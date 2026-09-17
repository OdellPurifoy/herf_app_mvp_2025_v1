- source_spec: `_bmad-output/specs/spec-rsvp-notification-fixes/stories/1-rsvp-reedit-lockout.md`
  summary: RsvpsController#update's invalid-params failure path (`render :show, status: :unprocessable_entity`) never sets `@guest_count_options`, which the show view's guest-count `<select>` requires (`@guest_count_options.map { ... }`) — raises NoMethodError on nil for any real request that submits an invalid RSVP update.
  evidence: Verified directly — `show` sets `@guest_count_options = (1..10).to_a` but `update` never does, and `app/views/rsvps/show.html.erb:144` calls `.map` on it unconditionally. Pre-existing (the render call predates this story's diff); not caused by the re-edit-lockout fix, though re-editing now reaches this path more often.

- source_spec: `_bmad-output/specs/spec-rsvp-notification-fixes/stories/1-rsvp-reedit-lockout.md`
  summary: Rsvp#mark_expired_if_past_due is dead code — `update_column(:status, :expired) if expired? && !expired?` can never be true, so the `status` column never actually becomes `:expired` and the `status_display` "Expired" branch and `Rsvp.expired` enum value are unreachable through normal app flow.
  evidence: Verified directly by reading app/models/rsvp.rb and confirming no other call site ever sets `status: :expired`. Pre-existing, unrelated to this story's fix (which is time-based via `expires_at`, not the `status` column).

- source_spec: `_bmad-output/specs/spec-rsvp-notification-fixes/stories/1-rsvp-reedit-lockout.md`
  summary: Rsvp's guest_count validation (`presence: true, numericality: { greater_than: 0 }`) is unconditional on status, so a `declined` RSVP is forced to carry a meaningless positive guest_count. User flagged this as illogical; deferred rather than fixed now.
  evidence: `total_attendees` already treats guest_count as irrelevant for non-attending RSVPs (`attending? ? guest_count : 0`), so this is a data-modeling quirk, not a functional bug — user chose to defer rather than make the validation conditional on `attending?`.

- source_spec: `_bmad-output/specs/spec-rsvp-notification-fixes/stories/2-event-cancellation-email.md`
  summary: ARCHITECTURE-SPINE.md's AD-8 ("every outbound email or SMS is enqueued via ActiveJob — deliver_later / *Job.perform_later — no controller, model, or service ever calls a mailer's deliver_now") is factually wrong. `app/jobs/event_reminder_job.rb` and `app/jobs/event_registration_confirmation_job.rb` both already call `.deliver_now` from inside a job, and this story's own fix needed to as well (OpenStruct params can't cross ActiveJob's serialization boundary that deliver_later requires). AD-8 should be corrected to permit deliver_now from within an already-async job, reserving the prohibition for the request cycle specifically.
  evidence: Verified directly — grepped all `deliver_later`/`deliver_now` call sites in app/jobs and app/models. Not fixed here per this workflow's own rule that edits to specs/architecture docs route to defer, not silent patch.

- source_spec: `_bmad-output/specs/spec-rsvp-notification-fixes/stories/2-event-cancellation-email.md`
  summary: Intermittent test-suite flakes — `spec/requests/explore_spec.rb:57` ("does not show past events") and `spec/requests/event_registrations_spec.rb:159` fail roughly 1 in 8 runs because `spec/factories/events.rb` names events with a single `Faker::Lorem.word`, which can coincidentally appear elsewhere in the rendered page and break `not_to include(event.name)`-style assertions. `membership_inquiry_mailer_spec.rb` showed similar order-dependent flakiness.
  evidence: Reran the two specs 8 times in isolation: 7 passes, 1 failure, with no changes to any file they exercise. Pre-existing; makes full-suite regression checks noisy. Fix would be distinctive factory names (e.g. `"Event #{SecureRandom.hex(4)}"`).

- source_spec: `_bmad-output/specs/spec-delete-link-and-confirms/stories/1-edit-page-delete-event-link.md`
  summary: Cross-tenant authorization hole — `EventsController#set_event`, `MembershipsController`, and `SpecialOffersController` load records with bare `find(params[:id])` and never check the record belongs to `current_lounge_owner`, so any subscribed owner can edit or delete another lounge's events, memberships, and special offers. User decision: spec an ownership-scoping fix right after the Delete Event / confirm stories (ARCHITECTURE-SPINE AD-4 points at Pundit).
  evidence: Verified in app/controllers/events_controller.rb:59-61, memberships_controller.rb:54, special_offers_controller.rb:67; only authenticate_lounge_owner! and check_subscription run before them. Found by the Story 1 spec reviewer; pre-existing.

- source_spec: `_bmad-output/specs/spec-delete-link-and-confirms/stories/1-edit-page-delete-event-link.md`
  summary: Story 1 review re-flagged the unscoped `Event.find(params[:id])` in `EventsController#set_event` — the edit-page Delete Event control now works, so this is one more way to reach the cross-owner delete already logged above.
  evidence: events_controller.rb:59-61; covered by the planned ownership-scoping spec.

- source_spec: `_bmad-output/specs/spec-delete-link-and-confirms/stories/1-edit-page-delete-event-link.md`
  summary: No automated test proves dismissing a Turbo confirm prompt cancels the action; needs `js: true` Capybara specs with `dismiss_confirm`, which require Chrome/chromedriver (not installed locally) and ideally CI (none exists).
  evidence: `spec/rails_helper.rb` sets `javascript_driver = :selenium_chrome_headless`, but `/Applications/Google Chrome.app` and `chromedriver` are absent; rack_test ignores `data-turbo-confirm`. Relevant again for Story 2's 41 prompts.

- source_spec: `_bmad-output/specs/spec-delete-link-and-confirms/stories/2-restore-confirm-prompts.md`
  summary: Five `app/views/admin_dashboard/*` "Log Out" buttons have no confirmation at all, so admin pages sign out on one click while every other page now prompts.
  evidence: `grep` for `destroy_lounge_owner_session_path` without `confirm` returns 5 hits on both this branch and baseline `c0130cf` (verified via `git stash`), so it is pre-existing; Story 2's frozen Boundaries forbid adding prompts to controls that lack one. The new guard spec allowlists exactly these 5, so removing them from the allowlist is all that's needed later.

- source_spec: `_bmad-output/specs/spec-delete-link-and-confirms/stories/2-restore-confirm-prompts.md`
  summary: `app/views/admins/registrations/edit.html.erb` is unreachable dead code — `config/routes.rb:8` declares `devise_for :admins, skip: [:registrations]`, so the `registration_path(resource_name)` it calls has no route. Delete the view or restore the routes.
  evidence: `bundle exec rails routes | grep -i "admin.*registration"` returns nothing. Pre-existing; found during Story 2 review because the file was edited.

- source_spec: `_bmad-output/specs/spec-delete-link-and-confirms/stories/2-restore-confirm-prompts.md`
  summary: The confirm message "Are you sure?" is now duplicated 44 times across views in two quote styles and says nothing about consequences (deleting an event emails and texts every member). Consider an i18n key or per-action wording.
  evidence: Wording was frozen by Story 2's intent ("keep every message verbatim"), so this is a deliberate follow-up rather than a defect.
