# SendGrid Email Setup Guide

This guide will help you configure SendGrid for email delivery in your HERF App.

## Step 1: Create SendGrid Account

1. Go to https://sendgrid.com/
2. Sign up for a free account (100 emails/day free tier)
3. Verify your email address

## Step 2: Create API Key

1. Log into SendGrid
2. Go to **Settings** → **API Keys**
3. Click **Create API Key**
4. Name: `HERF App Production`
5. Permissions: **Full Access** (or minimum "Mail Send")
6. Click **Create & View**
7. **COPY THE API KEY** (you'll only see it once!)

## Step 3: Verify Sender Email

SendGrid requires you to verify the email address you'll send from:

### Single Sender Verification (Easiest)

1. Go to **Settings** → **Sender Authentication**
2. Click **Single Sender Verification**
3. Click **Create New Sender**
4. Fill in your details:
   - **From Name**: HERF App (or your business name)
   - **From Email Address**: Your email (e.g., notifications@yourdomain.com or your personal email)
   - **Reply To**: Same as above or support email
   - Fill in address fields
5. Click **Create**
6. Check your email and click the verification link

### Domain Authentication (Recommended for Production)

For production, you should authenticate your domain:
1. Go to **Settings** → **Sender Authentication**
2. Click **Authenticate Your Domain**
3. Follow the DNS setup instructions
4. This improves deliverability and allows sending from any email @yourdomain.com

## Step 4: Configure Railway Environment Variables

1. Go to your Railway project dashboard
2. Click on your service
3. Go to **Variables** tab
4. Add these environment variables:

```
SENDGRID_API_KEY=SG.your_api_key_here
APP_HOST=your-app.up.railway.app
```

**Important**: Replace `your-app.up.railway.app` with your actual Railway domain.

## Step 5: Update ApplicationMailer

Make sure your `app/mailers/application_mailer.rb` has the correct default from address:

```ruby
class ApplicationMailer < ActionMailer::Base
  default from: 'notifications@yourdomain.com' # Must match verified sender
  layout 'mailer'
end
```

## Step 6: Test Email Delivery

### Local Testing (Development)

In development, emails open in your browser via letter_opener:

```bash
rails email:verify
rails email:test[your@email.com]
```

### Production Testing (Railway)

After deploying to Railway:

```bash
# SSH into Railway (or use Railway CLI)
rails email:test[your@email.com]
```

Or trigger an email through the app (e.g., create an event to send notifications).

## Step 7: Monitor Email Delivery

1. Go to https://app.sendgrid.com/email_activity
2. View all sent emails and their delivery status
3. Check for bounces, spam reports, or delivery issues

## Troubleshooting

### Email Not Received

1. **Check SendGrid Activity**: https://app.sendgrid.com/email_activity
2. **Verify sender email**: Make sure it's verified in SendGrid
3. **Check spam folder**: Emails might be filtered
4. **Review API key**: Ensure it has "Mail Send" permission
5. **Check Railway logs**: `railway logs` to see any errors

### Common Errors

**Error: "Sender address not verified"**
- Go to SendGrid Settings → Sender Authentication
- Verify your sender email address

**Error: "Authentication failed"**
- Check that SENDGRID_API_KEY is set correctly in Railway
- Verify the API key is still active in SendGrid

**Error: "Connection refused"**
- Ensure Railway allows outbound connections on port 587
- Check that SMTP settings are correct in production.rb

## SendGrid Free Tier Limits

- **100 emails per day** (free tier)
- Upgrade to paid plan for higher limits
- Monitor usage: https://app.sendgrid.com/statistics

## Alternative: Domain Email Setup

If you want to send from your own domain (e.g., notifications@herfapp.com):

1. **Buy a domain** (Namecheap, Google Domains, etc.)
2. **Authenticate domain in SendGrid** (Settings → Sender Authentication)
3. **Add DNS records** as instructed by SendGrid
4. **Update ApplicationMailer** with your domain email

## Next Steps

After setup:
- [ ] Create SendGrid account
- [ ] Get API key
- [ ] Verify sender email
- [ ] Add env vars to Railway
- [ ] Test email delivery
- [ ] Update ApplicationMailer default from address
- [ ] Monitor delivery in SendGrid dashboard

## Support

- SendGrid Docs: https://docs.sendgrid.com/
- SendGrid Support: https://support.sendgrid.com/
- HERF App Issues: Check your Rails logs
