---
id: SPEC-rsvp-notification-fixes
companions: ['../../planning-artifacts/architecture/architecture-herf_app_mvp_2025_v1-2026-09-16/ARCHITECTURE-SPINE.md']
sources: []
---

> **Canonical contract.** This SPEC and the files in `companions:` are the complete, preservation-validated contract for what to build, test, and validate. Source documents listed in frontmatter are for traceability — consult them only if you need narrative rationale or prose color this contract intentionally omits.

# RSVP Re-Edit Lockout and Missing Cancellation Email

## Why

A pain to solve. Two bugs from the user's backlog break member-facing communication around events: (1) a member who has already responded to an RSVP cannot change their mind or update their guest count — the link shows "expired" even though it isn't, and (2) deleting an event silently sends an SMS but never the "Event Cancelled" email, even though the mailer already exists and is tested. Both erode trust with lounge members and create support burden for lounge owners.

## Capabilities

- **CAP-1**
  - **intent:** A member who has already responded to an RSVP can still change their response (attending/declined, guest count) via the same link, any time before the RSVP's real expiry.
  - **success:** Visiting an unexpired RSVP link after a prior response renders the editable RSVP form, not the expired page; submitting a changed response updates `status`/`guest_count` and persists.

- **CAP-2**
  - **intent:** When a lounge owner deletes an event, every active member with email notifications enabled receives an "Event Cancelled" email, matching the SMS notice that already sends today.
  - **success:** Deleting an event results in `CancelledEventMailer#notify` being delivered (via `deliver_later`) to each eligible member; covered by a job/mailer spec asserting delivery.

## Constraints

- Reuse the existing `CancelledEventMailer` and its view as-is — already built and unit-tested; this is a wiring fix, not a new template.
- CAP-1's fix preserves the `expired?` guard exactly: an RSVP past its real `expires_at` must still render the expired page. Only the already-responded gate (`valid_for_response?` requiring `pending?`) loosens.
- CAP-2's email eligibility mirrors the SMS eligibility already in `EventDeletionNotificationJob` (active membership, notification-preference opt-in) but keyed on `allow_email_notifications` instead of `allow_text_notifications`.
- Implementation follows `ARCHITECTURE-SPINE.md` AD-1 (see companion): whether the mailer call extends the existing `EventDeletionNotificationJob` or moves to an explicit service is an implementation call, not fixed here.

## Non-goals

- Not building a general notification-dispatch framework or consolidating all notification triggers (tracked as Deferred in the architecture spine).
- Not changing RSVP expiration semantics — still 1 hour before event start.
- Not addressing the third backlog item ("cancel routes to a gone event page"). It is a real, separate bug in the edit page's Delete Event link, specced in `../spec-delete-link-and-confirms/`.

## Success signal

Both fixes are covered by passing RSpec examples (a request/controller spec re-responding to an already-answered, unexpired RSVP; a job/mailer spec asserting `CancelledEventMailer#notify` fires on event deletion), plus a manual pass in development confirming both flows.
