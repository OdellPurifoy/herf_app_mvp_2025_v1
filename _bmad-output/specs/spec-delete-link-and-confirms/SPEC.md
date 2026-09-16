---
id: SPEC-delete-link-and-confirms
companions: ['../../planning-artifacts/architecture/architecture-herf_app_mvp_2025_v1-2026-09-16/ARCHITECTURE-SPINE.md']
sources: []
---

> **Canonical contract.** This SPEC and the files in `companions:` are the complete, preservation-validated contract for what to build, test, and validate. Source documents listed in frontmatter are for traceability — consult them only if you need narrative rationale or prose color this contract intentionally omits.

# Broken Delete Event Link and Confirmation Prompts

## Why

A pain to solve. The "Delete Event" link on the event edit page (backlog bug #3) doesn't delete anything: it's written for rails-ujs, which this app doesn't load, so clicking it sends a GET to `/events/:id`. There's no show view there, so the owner lands on an error page. The same missing library means none of the app's 41 `data: { confirm: }` prompts ever appear, so deletes of events, memberships, and special offers fire on the first click. Event deletion also notifies members, so one misclick reaches people outside the app.

## Capabilities

- **CAP-1**
  - **intent:** A lounge owner can delete an event from its edit page and lands on the dashboard.
  - **success:** After confirming, the click sends `DELETE /events/:id`, the event is removed, the owner is redirected to the dashboard with the destroyed notice, and no `GET /events/:id` occurs.

- **CAP-2**
  - **intent:** Every action that declares a confirmation message prompts before proceeding.
  - **success:** For each of the 41 prompts, dismissing the dialog sends no request and accepting proceeds with the original action.

## Constraints

- Use Turbo's native `data-turbo-method` / `data-turbo-confirm`. Don't reinstall rails-ujs or add a JavaScript dependency; Hotwire via importmap is the established stack.
- Keep every confirm message's text verbatim and the same set of confirmed actions, sign-out included. This restores intended behavior; it doesn't redesign it.
- Event deletion still goes through `EventsController#destroy`, so its dashboard redirect and the `Event` `after_destroy` cancellation notifications still fire.

## Non-goals

- No `events/show` page.
- No new confirmation prompts and no wording changes.
- No rails-ujs.

## Success signal

In a browser, deleting an event from its edit page asks for confirmation, then removes the event and lands on the dashboard; dismissing any of the app's confirmation prompts leaves the action undone.
