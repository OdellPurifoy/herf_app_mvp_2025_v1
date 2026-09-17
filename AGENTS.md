<!-- bmad:context -->
<!-- Verified 2026-09-17 against c0130cf. Managed by bmad-project-context; edits inside this block are replaced on refresh. Keep anything you want preserved outside the markers. -->

## herf_app_mvp_2025_v1

SaaS platform for cigar lounge owners: subscriptions, events, memberships, RSVPs, special offers, and automated member notifications. Rails 7.1 / Ruby 3.3.1, PostgreSQL, Hotwire (Turbo+Stimulus) + Tailwind via Import Maps (no Node/webpack), Sidekiq+Redis for background jobs. Deeper technical reference: `APP_BREAKDOWN.md`.

## Policy

- Never remove the legacy Robusto/Churchill subscription plan code — may be reactivated.
- Fix the bug with the smallest change that does it; prefer deleting code over adding it; no new classes, callbacks, or abstractions unless the spec names them.

## Where things are

- Full model/controller/job/mailer breakdown: `APP_BREAKDOWN.md`
- Background jobs and Sidekiq operation: `BACKGROUND_JOBS_GUIDE.md`, `SIDEKIQ_SETUP.md`

## Running and verifying

- No CI is configured — `bundle exec rspec` and RuboCop only run locally; nothing gates merges yet.
- `js: true` feature specs use `selenium_chrome_headless` (Capybara) — need Chrome installed locally to pass.
- Stripe calls are stubbed per-spec via `spec/support/stripe_helpers.rb`, not globally — a spec that skips those helpers hits the real Stripe test API and needs valid `STRIPE_*` test keys.

## Conventions that differ from defaults

- All primary keys are UUIDs (`config/application.rb` generator default) — never assume integer IDs.
- App timezone is fixed to Eastern (`config.time_zone`) — don't assume UTC or server-local time.

## Known pitfalls

- `/admin` (`AdminDashboardController`) has `authenticate_admin!` commented out — no auth is enforced. Don't assume it's protected; don't silently re-enable it without asking.
- `SubscriptionManagementController` (`/subscription_management`) is a token-gated (`X-Admin-Token`/`ADMIN_TOKEN`) tool that grants subscriptions outside Stripe Checkout, marked `TODO: Remove this after initial setup` in the code — treat as temporary; don't extend it without confirming it's still needed.

<!-- /bmad:context -->
