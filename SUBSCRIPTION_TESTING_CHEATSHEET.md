# Subscription Testing Cheatsheet

## Creating Test Products and Prices in Stripe

### Using Stripe CLI
```bash
# Login to Stripe (if not already logged in)
stripe login

# Create Monthly product
stripe products create --name="Monthly" --description="HERF App Monthly Plan"

# Example Output:
# {
#   "id": "prod_12345abcde",
#   "name": "Monthly",
#   "description": "HERF App Monthly Plan",
#   ...
# }

# Create price for Monthly plan (copy the product ID from above)
stripe prices create --unit-amount=1900 --currency=usd --recurring[interval]=month --product=prod_12345abcde

# Example Output:
# {
#   "id": "price_monthly12345",
#   ...
# }

# Create Yearly product
stripe products create --name="Yearly" --description="HERF App Yearly Plan"

# Create price for Yearly plan (copy the product ID from above)
stripe prices create --unit-amount=4900 --currency=usd --recurring[interval]=year --product=prod_67890fghij
```

### Using Stripe Dashboard
1. Go to https://dashboard.stripe.com/test/products
2. Click "Add product"
3. Set name to "Monthly" and price to $19.00/month
4. Save product
5. Click "Add product" again
6. Set name to "Yearly" and price to $49.00/year
7. Save product
8. Get Price IDs from each product page

## Update Your .env File
```
STRIPE_MONTHLY_PRICE_ID=price_id_from_stripe_for_monthly_plan
STRIPE_YEARLY_PRICE_ID=price_id_from_stripe_for_yearly_plan
```

## Testing Webhooks

### Start Webhook Forwarding
```bash
stripe listen --forward-to localhost:3000/pay/webhooks/stripe
```

### Copy Webhook Secret
When you run the command above, it will output a webhook signing secret like:
```
Ready! Your webhook signing secret is whsec_abcdefghijklmnopqrstuvwxyz12345
```

Add this to your .env file:
```
STRIPE_SIGNING_SECRET=whsec_abcdefghijklmnopqrstuvwxyz12345
```

## Test Credit Cards

### Successful Payment
Card number: 4242 4242 4242 4242
Exp date: Any future date
CVC: Any 3 digits
ZIP: Any 5 digits

### Payment Requires Authentication
Card number: 4000 0025 0000 3155
Exp date: Any future date
CVC: Any 3 digits
ZIP: Any 5 digits

### Payment Declined
Card number: 4000 0000 0000 9995
Exp date: Any future date
CVC: Any 3 digits
ZIP: Any 5 digits
