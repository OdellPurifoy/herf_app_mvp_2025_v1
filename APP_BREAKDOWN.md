# HERF APP MVP 2025 — Full Technical Breakdown

## What This App Does (Plain English)

This is a SaaS platform for cigar lounge owners. A lounge owner pays a monthly subscription, creates their lounge profile, and then manages their members, events, and special offers from a dashboard. When something happens (new event, new special offer, event update, etc.), the app automatically emails and/or texts all of the lounge's members. Members can RSVP to events through unique tokenized links. There is also a super-admin panel for the platform operator.

---

## Tech Stack

- **Framework**: Ruby on Rails 7.1 (Ruby 3.3.1)
- **Database**: PostgreSQL (all primary keys are UUIDs)
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS, Import Maps — no Node/Webpack build pipeline
- **Background Jobs**: Sidekiq (with Redis) + sidekiq-cron for scheduled jobs
- **Authentication**: Devise (two separate user types: LoungeOwner and Admin)
- **Payments/Subscriptions**: Stripe via the Pay gem (v10)
- **Email**: SendGrid via sendgrid-actionmailer
- **SMS**: Twilio via twilio-ruby
- **File Uploads**: Active Storage (configured for AWS S3 in production)
- **Search/Filter**: Ransack
- **Pagination**: Kaminari
- **Error Monitoring**: Honeybadger
- **Testing**: RSpec, FactoryBot, Capybara, Shoulda-Matchers

---

## Database Schema (All Tables)

### Core Business Tables

**lounge_owners** — The paying customers of the platform. Fields: email, encrypted_password (Devise), first_name, last_name, phone_number, date_of_birth. This is the Devise user model with age validation (must be 18+) and DOB format validation.

**lounges** — A lounge belongs to a lounge_owner. Fields: name, address (street_1, street_2, city, state, zip_code), phone_number, email, description, facebook/x/instagram handles, website, and a set of boolean amenity flags (outside_cigars_allowed, outside_food_allowed, alcohol_served, outside_alcohol_allowed, food_served). Has Active Storage attachments for a logo and a cover_image.

**events** — Belongs to a lounge. Fields: name, event_type (from a predefined list of 10 types like "Live Music", "Whiskey Tasting", etc.), date, start_time, end_time, virtual (boolean), virtual_url, virtual_passcode, description, rsvp_needed (boolean), capacity, entry_fee. Has an Active Storage attachment for a flyer.

**memberships** — Belongs to a lounge. Represents an individual patron of the lounge. Fields: first_name, last_name, email, phone_number, opt_out_text_messaging (boolean), allow_text_notifications (boolean), allow_email_notifications (boolean), active (boolean). Has no login — members never log in to this app, they only receive notifications.

**rsvps** — Belongs to both an event and a membership (unique constraint on the pair). Fields: status (integer enum: 0=pending, 1=attending, 2=declined, 3=expired), guest_count (1-10), rsvp_token (UUID, unique, indexed), expires_at. RSVPs are accessed via a tokenized URL, not a login.

**special_offers** — Belongs to a lounge. Fields: name, offer_type (from list: BOGO, Half Off, Brand Discount, etc.), start_date, end_date, members_only (boolean), offer_code, description. Has an Active Storage attachment for a flyer.

**admins** — Separate Devise user model for the platform operator. Just email + encrypted_password.

### Subscription Tables (from the Pay gem)

The Pay gem creates five tables to wrap Stripe:
- **pay_customers** — polymorphic, owned by LoungeOwner. Holds the Stripe customer ID.
- **pay_subscriptions** — the active Stripe subscription record (name, processor_plan, status, current_period_start/end, trial/ends_at, pause info, metadata).
- **pay_charges** — individual charge records from Stripe.
- **pay_payment_methods** — stored payment methods.
- **pay_webhooks** — raw incoming Stripe webhook events stored for processing.
- **pay_merchants** — for Connect accounts (not actively used in this MVP).

### Rails Infrastructure Tables

- **active_storage_attachments / active_storage_blobs / active_storage_variant_records** — standard Active Storage tables for file uploads.

---

## Models — Relationships and Logic

### LoungeOwner
- `has_many :lounges, dependent: :destroy`
- `pay_customer default_payment_processor: :stripe` — wires up the Pay gem
- Age validation: must be 18+, DOB must be in the past in YYYY-MM-DD format
- `subscribed?` — checks if any Pay subscription is active
- `can_create_lounge?` — delegates to `subscribed?`
- `membership_limit` — returns the integer cap on members based on the active plan (50 / 300 / unlimited)
- `event_limit_per_month` — returns the integer cap on events per month per plan (2 / 4 / unlimited)
- `special_offer_limit_per_month` — returns the cap on special offers per month per plan (2 / 2 / unlimited)
- Helper methods: `corona_plan?`, `toro_plan?`, `robusto_plan?` (legacy), `churchill_plan?` (legacy), `subscription_name`

### Lounge
- `belongs_to :lounge_owner`
- `has_many :events, :special_offers, :memberships` — all `dependent: :destroy`
- `has_one_attached :logo` and `has_one_attached :cover_image`
- Validates presence of: name, address_street_1, city, state, zip_code, email

### Event
- `belongs_to :lounge`, `has_many :rsvps, dependent: :destroy`
- `has_one_attached :flyer`
- Predefined TYPES constant with 10 event categories
- Validates: name, event_type, date, start_time, end_time; virtual_url if virtual
- Custom validations: end_time must be after start_time; date cannot be in the past; event count for the month must not exceed the plan's `event_limit_per_month`
- Scope: `upcoming` — events from today forward, ordered by date and time
- `paginates_per 5`
- `ransackable_attributes` defined for Ransack search
- After callbacks:
  - `after_create :notify_members_of_creation` — fires SMS job
  - `after_create :create_rsvps_if_needed` — if rsvp_needed, creates an Rsvp record for every active member
  - `after_update :notify_members_of_update` — fires email job
  - `after_update :create_rsvps_if_rsvp_enabled` — handles the case where rsvp_needed is toggled on during update
  - `after_destroy :notify_members_of_deletion` — fires email job
- `create_rsvps_for_members!` — iterates active memberships in a transaction, creates RSVPs with expiry set to 1 hour before the event
- `total_confirmed_attendees`, `pending_rsvps_count`, `attending_rsvps_count`, `declined_rsvps_count`

### Membership
- `belongs_to :lounge`, `has_many :rsvps, dependent: :destroy`
- `has_person_name` — from the name_of_person gem (adds full_name, initials helpers)
- Validates presence of first_name and last_name
- Custom validation: `membership_limit_not_exceeded` — checks current membership count against `lounge_owner.membership_limit` on create
- Scopes: `active` and `inactive`
- `paginates_per 5`
- Ransack-enabled for searching by name, email, phone, notification preferences
- `rsvp_for_event(event)`, `pending_rsvps`, `upcoming_events_attending`

### Rsvp
- `belongs_to :event`, `belongs_to :membership`
- Integer enum: `pending: 0`, `attending: 1`, `declined: 2`, `expired: 3`
- Validates: guest_count (1-10), rsvp_token uniqueness, expires_at, and uniqueness of event_id + membership_id pair
- `before_validation :generate_rsvp_token` — auto-generates a secure token on create
- `before_validation :set_expiration_date` — sets expiry 1 hour before event
- `after_update :mark_expired_if_past_due`
- Scopes: `valid`, `expired`, `for_upcoming_events`
- `respond_with(status, guest_count)` — the main update method, guards against expired state
- `status_display` — human-readable status string for views
- `find_by_token(token)` class method — used for tokenized URL lookup

### SpecialOffer
- `belongs_to :lounge`
- `has_one_attached :flyer`
- TYPES constant with 5 offer categories
- Validates: name, offer_type, start_date, end_date; end_date must be after start_date; monthly offer count must not exceed plan limit
- Scope: `upcoming`
- `paginates_per 5`
- After callbacks for creation, update, and destruction — fire email notification jobs

### SubscriptionPlan (NOT a database model — pure Ruby class)
- A static PLANS hash with four entries: `robusto_monthly` (legacy, $49/mo), `churchill_monthly` (legacy, $99/mo), `corona_monthly` ($19/mo, active), `toro_monthly` ($39/mo, active)
- Each entry has a name, a Stripe price ID (read from ENV), amount in cents, interval, and a features array
- `self.find(name)` — looks up a plan by symbol key

---

## Controllers

### ApplicationController
- `configure_permitted_parameters` for Devise sign_up/account_update to allow first_name, last_name, date_of_birth, phone_number
- `after_sign_in_path_for` → `dashboard_path`
- `check_subscription` — shared before_action used across multiple controllers; redirects to dashboard with an alert if no active subscription

### HomeController
- Loads FAQs from `config/faqs.yml` and renders the public marketing/landing page

### DashboardController
- Requires `authenticate_lounge_owner!`
- `index`: loads the lounge owner's first lounge, upcoming events, upcoming special offers, and subscription status — this is the main authenticated page after login

### LoungesController
- Public: `index`, `show` (no auth required)
- Authenticated: `new`, `create`, `edit`, `update`, `destroy`
- `check_subscription` before_action on `new`/`create` — subscription required to create a lounge
- Supports Turbo Stream responses on create and update

### EventsController
- All actions require `authenticate_lounge_owner!` and `check_subscription`
- Ransack search on index (`@q = @lounge.events.ransack(params[:q])`)
- Kaminari pagination on index
- On create: fires `new_event_mailer` (email to all members)
- On update: fires `updated_event_mailer` with changed_attributes list
- Supports Turbo Stream

### MembershipsController
- All actions require authentication and subscription
- Ransack + Kaminari on index
- On create: fires `new_membership_mailer`
- On update: fires `updated_membership_mailer`
- On destroy: fires `cancelled_membership_mailer` before destroying

### SpecialOffersController
- All actions require authentication and subscription
- Ransack + Kaminari on index
- On create/update/destroy: fires appropriate mailer

### RsvpsController
- `index` (lounge owner view of all RSVPs for an event) — requires authentication and authorization check that the event belongs to the lounge owner
- `show` — public, token-based. Finds RSVP by token from URL. Renders expired view if expired.
- `update` — public, token-based. Calls `rsvp.respond_with(status, guest_count)`. Guards against expired RSVPs.
- No login required for members to respond — authentication is the possession of the unique token.

### SubscriptionsController
- Requires `authenticate_lounge_owner!`
- `new`: looks up the selected plan from SubscriptionPlan
- `create`: calls `current_lounge_owner.payment_processor.checkout(...)` with the Stripe price ID; redirects to Stripe Checkout
- `success` / `cancel`: Stripe redirect-back endpoints
- `billing_portal`: creates a Stripe Billing Portal session and redirects to it for plan changes/cancellations

### AdminDashboardController
- (Note: `authenticate_admin!` is currently commented out — auth is disabled)
- `index`: aggregate counts of lounge_owners, events, rsvps, special_offers
- `lounge_owners`, `events`, `rsvps`, `special_offers`: list views with eager loading
- `member_upload`: accepts a CSV file upload and bulk-creates Membership records for a given lounge. Validates file type, validates lounge existence, parses CSV row by row.

---

## Subscription Plans and Enforcement

The platform has four plans (two legacy, two active):

| Plan             | Price | Members   | Events/mo | Special Offers/mo |
|------------------|-------|-----------|-----------|-------------------|
| Robusto (legacy) | $49   | 50        | 2         | 2                 |
| Churchill (legacy)| $99  | 150       | Unlimited | Unlimited         |
| Corona (active)  | $19   | 300       | 4         | 2                 |
| Toro (active)    | $39   | Unlimited | Unlimited | Unlimited         |

Enforcement happens at the model level via custom validations:
- Creating a Membership triggers `membership_limit_not_exceeded`
- Creating an Event triggers `event_limit_not_exceeded` (checks events created this month)
- Creating a SpecialOffer triggers `special_offer_limit_not_exceeded` (checks offers this month)

Stripe integration flows:
1. User selects a plan on the home page pricing section → hits `SubscriptionsController#create`
2. App creates a Stripe Checkout Session and redirects to Stripe's hosted checkout
3. Stripe redirects back to `success_subscription_url` or `cancel_subscription_url`
4. Stripe sends webhooks → Pay gem processes them → updates `pay_subscriptions` and `pay_customers` tables
5. `lounge_owner.subscribed?` reads from the Pay tables to determine active status at runtime

---

## Background Jobs (Sidekiq)

All jobs extend `ApplicationJob` which uses `queue_as :default`. Sidekiq processes these asynchronously with Redis as the queue backend.

### Event-driven jobs (fired from model callbacks):

**EventCreationNotificationJob** — On event create. Finds all active memberships of the lounge. For each member with `allow_text_notifications?` and not `opt_out_text_messaging?`, sends an SMS via SmsNotificationService. Skipped in non-production unless ENV['ENABLE_SMS'] is set.

**EventUpdateNotificationJob** — On event update. Sends email to members about the update.

**EventDeletionNotificationJob** — On event destroy. Sends email to members that the event was cancelled.

**RsvpNotificationJob** — Fired after an RSVP is created. Sends an RSVP invitation email via RsvpNotificationMailer if the member allows email notifications.

**RsvpSmsNotificationJob** — Fired after an RSVP is created. Sends an SMS with the tokenized RSVP URL via SmsNotificationService. Skipped in non-production unless enabled.

**SpecialOfferCreationNotificationJob** — On special offer create. SMS notification to members.

**SpecialOfferUpdateNotificationJob** — On special offer update. Email notification.

**SpecialOfferDeletionNotificationJob** — On special offer destroy. Email notification.

### Scheduled jobs (via sidekiq-cron):

**OneWeekEventReminderJob** — Runs every day at 9:00 AM Eastern. Queries for events happening exactly 7 days from today, sends reminder emails to all active members of each lounge.

**OneDayEventReminderJob** — Runs every day at 6:00 PM Eastern. Queries for events happening exactly 1 day from today, sends reminder emails.

Both scheduled jobs use `EventReminderMailer` with separate one_week_reminder and one_day_reminder methods.

---

## Mailers (13 mailer classes)

All mailers extend `ApplicationMailer` and are delivered with `deliver_later` (enqueued through Sidekiq/Active Job).

- **NewEventMailer** — "New Event" or "RSVP Required" email on event creation. If rsvp_needed, includes the member's unique RSVP URL.
- **UpdatedEventMailer** — Notifies members when an event is updated, includes what changed.
- **CancelledEventMailer** — Notifies members when an event is deleted.
- **EventReminderMailer** — One-week and one-day reminders.
- **NewMembershipMailer** — Welcome email when a member is added to a lounge.
- **UpdatedMembershipMailer** — Notification when membership info changes.
- **CancelledMembershipMailer** — Notification when a membership is removed.
- **NewSpecialOfferMailer** — Notifies members of a new special offer.
- **UpdatedSpecialOfferMailer** — Notifies members when a special offer changes.
- **CancelledSpecialOfferMailer** — Notifies members when a special offer is removed.
- **RsvpNotificationMailer** — Sends the RSVP invitation email with the tokenized URL.
- **TestMailer** — Development/testing utility mailer.

Email delivery in production goes through SendGrid (`sendgrid-actionmailer`). In development, `letter_opener` is used to preview emails in the browser without actually sending them.

---

## SMS Notification Service

`SmsNotificationService` is a plain Ruby service object in `app/services/`.

- Constructor takes `to:` (phone number) and `body:` (message text)
- `send_message` — validates the phone number, then calls the Twilio REST API via `twilio-ruby`
- Reads credentials from Rails credentials/ENV: Twilio account SID, auth token, and the sending phone number
- Has a test mode (`enable_test_mode!` / `test_messages`) for use in specs — stores sent messages in memory instead of hitting Twilio
- In non-production environments, SMS is skipped unless `ENABLE_SMS` environment variable is present
- Phone numbers are formatted (strips non-digits, adds +1 country code) before being passed to Twilio

---

## RSVP Workflow (End-to-End)

1. Lounge owner creates an event with `rsvp_needed: true`
2. `after_create :create_rsvps_if_needed` runs inside the Event model — iterates all active memberships and creates one Rsvp record per member. Each Rsvp gets a secure random token and an expiry of 1 hour before the event start.
3. `after_create :notify_members_of_creation` fires `EventCreationNotificationJob` — sends SMS to members with `allow_text_notifications`
4. `NewEventMailer#notify` is called from the controller for each member — sends email with the subject "RSVP Required: [event name]" and includes a link like `https://app.com/rsvp/[token]`
5. `RsvpNotificationJob` and `RsvpSmsNotificationJob` also fire for each RSVP to send the dedicated RSVP invitation
6. Member clicks the link → `RsvpsController#show` looks up `Rsvp.find_by(rsvp_token: token)`, renders a form showing event details and a dropdown for guest_count (1-10) with attend/decline buttons
7. Member submits → `RsvpsController#update` → calls `rsvp.respond_with(status, guest_count)` → updates status to attending or declined
8. If the link is expired, the controller renders a separate `expired` view with status 410 Gone
9. Lounge owner can view all RSVPs for an event at `/events/:event_id/rsvps` — sees a table with status, guest_count, member names, and a summary

---

## Routing Structure

```
/                              → HomeController#index (public marketing page)
/dashboard                     → DashboardController#index (authenticated lounge owner hub)
/lounges                       → LoungesController (RESTful, nested resources below)
  /lounges/:id/events          → EventsController
    /events/:id/rsvps          → RsvpsController#index (shallow nested)
  /lounges/:id/special_offers  → SpecialOffersController (shallow)
  /lounges/:id/memberships     → MembershipsController (shallow)
/rsvp/:token                   → RsvpsController#show (public, token-auth)
/subscription                  → SubscriptionsController (new, create, success, cancel, billing_portal)
/admin                         → AdminDashboardController#index
/admins/sign_in                → Devise sessions for Admin
/sidekiq                       → Sidekiq Web UI (mounted directly)
/subscription_management       → SubscriptionManagementController (manual grant tool, temp)
```

Devise handles all of `/lounge_owners/sign_in`, `/lounge_owners/sign_up`, `/lounge_owners/password` etc. automatically.

---

## Frontend Architecture

- **No Node.js, no webpack, no npm.** The JS side uses Rails Import Maps — JavaScript modules are served directly via the browser's native ESM.
- **Hotwire Turbo** — most form submissions and redirects use Turbo Drive for SPA-like navigation without full page reloads. Controllers respond to both `format.html` and `format.turbo_stream`.
- **Stimulus** — lightweight JS controllers for interactivity. Files live in `app/javascript/controllers/`.
- **Tailwind CSS** — utility-first CSS, configured in `config/tailwind.config.js`, compiled by the `tailwindcss-rails` gem.
- **Active Storage** — images (logo, cover_image, flyer) are uploaded, stored in S3 in production, and served via signed URLs. Image variants are processed with `image_processing` gem (ImageMagick/Vips).

---

## Authentication and Authorization

Two completely separate Devise models:
- **LoungeOwner** — primary user type. Registers with email, password, name, DOB. Modules: database_authenticatable, registerable, recoverable, rememberable, validatable.
- **Admin** — platform operator. Modules: database_authenticatable, recoverable, rememberable, validatable. Registration is disabled (`skip: [:registrations]`). Admin sessions handled by a custom `Admins::SessionsController`.

Authorization is role-based but manual — no Pundit/CanCan:
- `authenticate_lounge_owner!` before_action on all protected controllers (from Devise)
- `check_subscription` before_action verifies an active Pay subscription exists
- `find_event_and_authorize` in RsvpsController verifies the event belongs to the current owner's lounge
- Member RSVP pages are token-authenticated — no login, but the token is a secret

---

## Infrastructure and Configuration

- **Procfile** (production): runs `web: bundle exec puma` and `worker: bundle exec sidekiq`
- **Procfile.dev** (development): runs Rails, Tailwind watch, and Sidekiq together
- **Dockerfile**: containerized deployment
- **config/sidekiq.yml**: Sidekiq config with concurrency and queue settings
- **config/sidekiq_schedule.yml**: Cron definitions for OneWeekEventReminderJob (9 AM Eastern daily) and OneDayEventReminderJob (6 PM Eastern daily)
- **config/application.rb**: sets time zone to Eastern Time, configures UUID primary keys globally, sets Active Job adapter to Sidekiq
- **config/faqs.yml**: static FAQ content loaded by HomeController
- **config/storage.yml**: Active Storage service configuration (local for dev, S3 for prod)
- **Honeybadger**: error monitoring gem configured via `config/honeybadger.yml`
- **Bullet** (dev/test): N+1 query detection
- **Rack Mini Profiler**: performance profiling in dev

---

## Test Suite

Located in `spec/`. Uses RSpec with the following structure:
- `spec/models/` — model unit tests
- `spec/controllers/` — controller tests
- `spec/requests/` — request/integration tests
- `spec/mailers/` — mailer tests
- `spec/jobs/` — job tests
- `spec/features/` — Capybara/Selenium feature/browser tests
- `spec/services/` — service object tests
- `spec/sidekiq/` — Sidekiq-specific job tests
- `spec/factories/` — FactoryBot factory definitions
- `spec/support/` — shared helpers, shoulda-matchers config, etc.

---

## Summary of Data Flow (Typical Lounge Owner Journey)

1. Owner visits the homepage, reads pricing, clicks a plan
2. Devise registration (name, email, password, DOB)
3. Redirected to dashboard — no subscription yet, sees prompt to subscribe
4. Selects a plan → Stripe Checkout → pays → Stripe webhook → Pay gem marks subscription active
5. Dashboard now unlocked — owner creates their Lounge (name, address, amenities, logo, cover photo)
6. Owner adds members manually or via CSV bulk upload (first_name, last_name, email, phone)
7. Owner creates an Event — system auto-creates RSVPs for all members if rsvp_needed, fires email + SMS notifications
8. Members receive emails/texts, click RSVP link, respond
9. Owner sees RSVP dashboard showing who's attending and total headcount
10. The day before the event, Sidekiq cron fires OneDayEventReminderJob → reminder emails to all members
11. Owner creates Special Offers — members are notified by email
12. Owner manages billing through Stripe Billing Portal at `/subscription/billing_portal`
13. Platform admin monitors everything via `/admin` and the Sidekiq Web UI at `/sidekiq`

---

## Notable Architectural Decisions and Known Gaps

- **The RSVP system is the most sophisticated piece** — tokenized URLs, expiry logic, capacity tracking, and dual email+SMS delivery all tied to a single event creation.
- **The subscription gates are scattered** — plan limits are enforced in three different model validation methods and a controller before_action. A future version might benefit from centralizing this in a policy layer.
- **Members have no login** — they're purely notification recipients who interact only via email/SMS links. This is a major architectural decision for v2 to reconsider.
- **The admin panel has authentication disabled** (`authenticate_admin!` is commented out) — that's a security gap to address.
- **Two legacy plans (Robusto/Churchill) coexist with two active plans (Corona/Toro)** — the plan detection code has multiple `case` statements that would need updating each time a plan is added or retired.
- **Each lounge owner currently manages only one lounge** — the dashboard loads `lounges.first`. The data model supports many lounges per owner but the UI/UX only exposes one.
