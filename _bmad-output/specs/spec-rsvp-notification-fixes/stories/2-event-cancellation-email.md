---
title: 'Send event-cancellation email on delete'
type: 'bugfix'
created: '2026-09-16'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context: ['{project-root}/_bmad-output/planning-artifacts/architecture/architecture-herf_app_mvp_2025_v1-2026-09-16/ARCHITECTURE-SPINE.md']
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `CancelledEventMailer` exists, is fully built and unit-tested, but has zero call sites in the application. When a lounge owner deletes an event, `EventDeletionNotificationJob` only sends an SMS — members with email notifications enabled never receive an "Event Cancelled" email.

**Approach:** On event deletion, send `CancelledEventMailer#notify` to each eligible member. Extend `Event#notify_members_of_deletion`'s `event_data` hash with the fields the mailer's view needs (`start_time`, lounge `name`/`email`/`phone_number`), since the Event record is already destroyed by the time any job runs.

**Decisions (user):**
- Eligibility respects notification preferences — active membership + `allow_email_notifications` — matching the SMS side, not `NewEventMailer`/`UpdatedEventMailer` (which email every membership unconditionally).
- Email runs in its own job (`EventDeletionEmailNotificationJob`), independent of the SMS job, so an email failure and Sidekiq retry can never resend SMS.

</frozen-after-approval>

## Implementation Notes

- New `EventDeletionEmailNotificationJob`; `Event#notify_members_of_deletion` now enqueues it alongside the unchanged SMS `EventDeletionNotificationJob` (restored byte-identical to `main`).
- Mailer is sent with `deliver_now`, not `deliver_later`: the mailer's `event:` param is an `OpenStruct` stand-in for the destroyed event, which ActiveJob can't serialize (`ActiveJob::SerializationError`). We're already inside an async job, and `event_reminder_job.rb` / `event_registration_confirmation_job.rb` already use `deliver_now` the same way.
- That contradicts `ARCHITECTURE-SPINE.md` AD-8 ("every outbound email... deliver_later") — AD-8 is inaccurate against the real codebase. Logged in `deferred-work.md` rather than edited here.
- `ApplicationHelper#format_phone_number` now calls `.to_s` first: nothing requires a lounge to have a phone number, and `nil.gsub` would have crashed the cancellation email render.
- Removed a stale "Assuming you have a members association" comment on the `member_ids:` line.
- Specs: SMS job's empty `pending` placeholder replaced with real SMS coverage; new spec for the email job covers eligibility, all rendered event fields, nil lounge phone, blank member_ids, and channel isolation; `event_spec.rb` asserts both jobs enqueue with the extended `event_data`.
- Full suite: 361 examples, 3 failures — all pre-existing in `subscription_flow_spec.rb` (verified identical on `main` via `git stash`). Separately found intermittent flakes from `Faker::Lorem.word` event names; logged in `deferred-work.md`.

## Review Triage Log

- **high, patched** — `format_phone_number(nil)` raises on `nil.gsub`; a lounge without a phone would crash every cancellation email. Newly reachable because this mailer was never called before. Fixed with `.to_s`, covered by a spec.
- **medium, patched (user decision)** — Email failure mid-job would fail the combined job and Sidekiq's retry would resend all SMS. Resolved by moving email into its own independent job. Residual: a failure partway through the email job can still resend emails to already-emailed members on retry — no SMS cost, accepted.
- **medium, patched** — Content spec only asserted subject/name/lounge name, not `start_time`, lounge email, or phone — the exact fields this change threads through. Added all.
- **low, patched** — "blank member_ids" spec never exercised the SMS job's blank guard (the env gate returned first). SMS job spec now stubs `ENABLE_SMS` before asserting.
- **low, patched** — Duplicate `Membership.where` queries and inconsistent `each`/`find_each` across the two channels. Moot after the split: each job queries once.
- **low, patched** — Stale "Assuming you have a members association" comment removed.
- **false** — Blank lounge `email`: `Lounge` validates `email` presence, so it can't be blank.
