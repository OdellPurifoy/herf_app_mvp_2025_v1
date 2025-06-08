# Testing Subscriptions

## Prerequisites

1. You need a Stripe account with test mode enabled
2. You need to set up the following environment variables in your `.env` file:
   ```
   STRIPE_PUBLIC_KEY=pk_test_your_public_key
   STRIPE_PRIVATE_KEY=sk_test_your_private_key
   STRIPE_SIGNING_SECRET=whsec_your_webhook_signing_secret
   STRIPE_HOBBY_PRICE_ID=price_your_hobby_price_id
   STRIPE_ENTERPRISE_PRICE_ID=price_your_enterprise_price_id
   ```

## Setting up Stripe Products and Prices

1. Create products and prices in Stripe Dashboard or using Stripe CLI:

```bash
# Create Hobby product
stripe products create --name="Hobby" --description="HERF App Hobby Plan"

# Create price for Hobby (note the product ID from the output)
stripe prices create --unit-amount=1900 --currency=usd --recurring[interval]=month --product=prod_YOUR_PRODUCT_ID

# Create Enterprise product
stripe products create --name="Enterprise" --description="HERF App Enterprise Plan"

# Create price for Enterprise (note the product ID from the output)
stripe prices create --unit-amount=4900 --currency=usd --recurring[interval]=month --product=prod_YOUR_PRODUCT_ID
```

2. Update your `.env` file with the price IDs

## Setting up Stripe Webhooks

Webhooks are essential for subscription events (such as payment successes, failures, cancelations):

1. Install the Stripe CLI: https://stripe.com/docs/stripe-cli

2. Login and listen for webhooks:

```bash
stripe login
stripe listen --forward-to localhost:3000/pay/webhooks/stripe
```

3. Copy the webhook signing secret that is displayed and add it to your `.env` file:

```
STRIPE_SIGNING_SECRET=whsec_your_webhook_signing_secret
```

## Testing the Subscription Flow

1. Start your Rails server:

```bash
rails server
```

2. Make sure your Stripe webhooks forwarder is running:

```bash
stripe listen --forward-to localhost:3000/pay/webhooks/stripe
```

3. Visit your application at http://localhost:3000

4. Sign up or log in as a lounge owner

5. Click on a subscription plan ("Hobby" or "Enterprise")

6. Complete the checkout process using test card numbers:
   - Successful payment: 4242 4242 4242 4242
   - Failed payment: 4000 0000 0000 0002

7. After successful subscription, you will be redirected to the dashboard

## Managing Subscriptions

- Users can manage their subscriptions via the billing portal
- Lounge owners with active subscriptions can create lounges, events, etc.
- Subscription status is displayed on the dashboard

## Testing Subscription Content Restrictions

1. Try to create a lounge without a subscription - you should be redirected
2. Subscribe to a plan
3. Now you should be able to create a lounge and manage events, offers, and memberships
