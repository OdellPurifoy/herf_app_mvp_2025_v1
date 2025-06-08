# HERF App - Cigar Lounge Management

This is a Rails application for managing cigar lounges, events, special offers, and memberships with subscription capabilities.

## Prerequisites

- Ruby 3.3.1
- Rails 7.1.5
- PostgreSQL
- Stripe account (for subscription processing)
- Twilio account (for SMS notifications)

## Setup

1. Clone the repository
2. Run `bundle install` to install dependencies
3. Set up the database with `rails db:create db:migrate db:seed`
4. Set up environment variables in a `.env` file:

```
# Twilio Configuration
TWILIO_ACCOUNT_SID=your_twilio_account_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_PHONE_NUMBER=your_twilio_phone_number

# Stripe Configuration
STRIPE_PUBLIC_KEY=pk_test_your_stripe_public_key
STRIPE_PRIVATE_KEY=sk_test_your_stripe_private_key
STRIPE_SIGNING_SECRET=whsec_your_stripe_webhook_signing_secret
STRIPE_MONTHLY_PRICE_ID=price_your_monthly_plan_id
STRIPE_YEARLY_PRICE_ID=price_your_yearly_plan_id
```

5. Start the Rails server with `rails server`

## Stripe Subscription Setup

1. Create products in Stripe:
   - Monthly Plan ($19/month)
   - Yearly Plan ($49/year)

2. Get the price IDs from Stripe and add them to your `.env` file.

3. Run the Stripe webhook listener in development:
   ```bash
   stripe listen --forward-to localhost:3000/pay/webhooks/stripe
   ```

## Features

- Lounge owner authentication (Devise)
- Subscription management (Pay gem with Stripe)
- Lounge management
- Event management
- Special offer management
- Membership management
- SMS and email notifications
