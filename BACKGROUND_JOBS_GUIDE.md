# Background Jobs Guide

This guide explains how background job processing works in the HERF application using Sidekiq and Redis.

---

## 🎯 What Problem Does This Solve?

Without background jobs, when a user creates an event in your app:
1. The web request waits while sending emails to 100+ members
2. The user's browser sits there spinning for 30+ seconds
3. If something fails, the whole request fails
4. The server can only handle a few requests at a time

**With background jobs:**
1. Event is created instantly (< 1 second)
2. User sees success message immediately
3. Emails are sent in the background by Sidekiq
4. If emails fail, they automatically retry
5. Server can handle many more concurrent users

---

## 🛠️ Technology Stack

### Redis
**What it is:** An in-memory data store (like a super-fast database that lives in RAM)

**What it does in HERF:**
- Stores the queue of background jobs waiting to be processed
- Keeps track of which jobs are running, failed, or completed
- Acts as the "to-do list" for Sidekiq

**Analogy:** Think of Redis as a digital bulletin board where you post sticky notes (jobs) that need to be done.

### Sidekiq
**What it is:** A background job processor for Ruby applications

**What it does in HERF:**
- Monitors the Redis queue for new jobs
- Processes jobs in the background (sends emails, SMS, etc.)
- Automatically retries failed jobs
- Provides a web dashboard to monitor everything

**Analogy:** Think of Sidekiq as workers who constantly check the bulletin board (Redis), grab tasks, complete them, and then grab the next one.

### Active Job
**What it is:** Rails' built-in framework for creating and managing background jobs

**What it does in HERF:**
- Provides a consistent interface for creating jobs
- Automatically integrates with Sidekiq
- Makes it easy to queue jobs from anywhere in your Rails app

**Analogy:** Active Job is like the standard format for writing tasks on sticky notes so any worker (Sidekiq, Delayed Job, etc.) can understand them.

---

## 📋 How It Works (Step by Step)

### Example: User Creates an Event

```ruby
# 1. Controller action (happens immediately)
def create
  @event = Event.new(event_params)
  @event.save  # Takes < 1 second
  
  # 2. After saving, Rails triggers this automatically (from event.rb model)
  EventCreationNotificationJob.perform_later(@event.id)
  
  # 3. User sees success message RIGHT AWAY
  redirect_to @event, notice: "Event created!"
end
```

**Behind the scenes:**
1. `perform_later` creates a job record in Redis (takes milliseconds)
2. Sidekiq worker sees the new job in Redis
3. Sidekiq grabs the job and executes it in the background
4. If it fails, Sidekiq automatically retries (25 times over 21 days)

---

## 🚀 Jobs in the HERF Application

### Email Jobs

#### **OneWeekEventReminderJob**
- **When it runs:** Daily at 9:00 AM (scheduled via cron)
- **What it does:** Finds events exactly 7 days away and sends reminder emails to members
- **Test mode:** `OneWeekEventReminderJob.perform_now(test_mode: true)` (sends to any upcoming event)

#### **OneDayEventReminderJob**
- **When it runs:** Daily at 6:00 PM (scheduled via cron)
- **What it does:** Finds events exactly 1 day away and sends reminder emails to members
- **Test mode:** `OneDayEventReminderJob.perform_now(test_mode: true)` (sends to any upcoming event)

#### **EventCreationNotificationJob** (Email only)
- **When it runs:** Automatically when an event is created
- **What it does:** Sends "New Event" emails to all active members

#### **EventUpdateNotificationJob**
- **When it runs:** Automatically when an event is updated
- **What it does:** Sends "Event Updated" emails to all active members

#### **EventDeletionNotificationJob**
- **When it runs:** Automatically when an event is deleted
- **What it does:** Sends "Event Cancelled" emails to all active members

### SMS Jobs (Disabled in Development)

All SMS jobs are **automatically skipped** in development to prevent Twilio errors:
- `EventCreationNotificationJob` (SMS version)
- `EventUpdateNotificationJob` (SMS version)
- `EventDeletionNotificationJob` (SMS version)
- `RsvpSmsNotificationJob`
- `SpecialOfferCreationNotificationJob`
- `SpecialOfferUpdateNotificationJob`
- `SpecialOfferDeletionNotificationJob`

**To enable SMS in development:** Set environment variable `ENABLE_SMS=true`

---

## 🎮 How to Use

### Starting Everything

**Option 1: Start all services together (Recommended)**
```bash
bin/dev
```
This starts:
- Rails server (port 3000)
- Tailwind CSS watcher
- Sidekiq worker

**Option 2: Start services separately**
```bash
# Terminal 1: Rails server
bin/rails server

# Terminal 2: Sidekiq
bundle exec sidekiq

# Terminal 3: Tailwind
bin/rails tailwindcss:watch
```

### Monitoring Jobs

**Sidekiq Web Dashboard:** [http://localhost:3000/sidekiq](http://localhost:3000/sidekiq)

The dashboard shows:
- **Processed:** Total jobs completed
- **Failed:** Jobs that failed (click to see errors and retry)
- **Busy:** Jobs currently running
- **Enqueued:** Jobs waiting in queue
- **Scheduled:** Jobs scheduled for future execution
- **Retries:** Failed jobs waiting to retry

### Testing Jobs Manually

**In Rails console:**
```ruby
# Run a job immediately (synchronously)
OneWeekEventReminderJob.perform_now(test_mode: true)

# Queue a job to run in background (asynchronously)
OneWeekEventReminderJob.perform_later(test_mode: true)

# Queue a job to run in 5 minutes
OneWeekEventReminderJob.set(wait: 5.minutes).perform_later

# Check how many jobs are queued
Sidekiq::Queue.new.size

# Check failed jobs
Sidekiq::RetrySet.new.size

# Retry all failed jobs
Sidekiq::RetrySet.new.each(&:retry)

# Clear all queued jobs (use with caution!)
Sidekiq::Queue.new.clear
```

### Checking Redis

```bash
# Check if Redis is running
redis-cli ping
# Should return: PONG

# View Redis info
redis-cli info

# Monitor Redis commands in real-time
redis-cli monitor
```

---

## ⏰ Scheduled Jobs (Cron)

The app uses the `whenever` gem to schedule recurring jobs.

**Current schedule** (see `config/schedule.rb`):
- **9:00 AM daily:** Send one-week event reminders
- **6:00 PM daily:** Send one-day event reminders

### Viewing the Schedule

```bash
# Preview what will be added to crontab
whenever

# Update the crontab (production)
whenever --update-crontab

# View current crontab
crontab -l

# Remove all scheduled jobs
whenever --clear-crontab
```

### Testing Scheduled Jobs

You don't need to wait for the scheduled times! Just run manually:
```ruby
# Test one-week reminders
OneWeekEventReminderJob.perform_now

# Test one-day reminders
OneDayEventReminderJob.perform_now

# Test with test mode (uses any upcoming events)
OneWeekEventReminderJob.perform_now(test_mode: true)
OneDayEventReminderJob.perform_now(test_mode: true)
```

---

## 🐛 Troubleshooting

### Sidekiq won't start
```bash
# Check if Redis is running
redis-cli ping

# If not running, start Redis
brew services start redis

# Or manually
redis-server
```

### Jobs aren't processing
1. Check Sidekiq is running: Visit [http://localhost:3000/sidekiq](http://localhost:3000/sidekiq)
2. Check the logs: `tail -f log/development.log`
3. Restart Sidekiq: Stop `bin/dev` and start again

### Jobs are failing
1. Visit the Sidekiq dashboard
2. Click "Dead" or "Retries" tab
3. Click on a failed job to see the error
4. Fix the issue in code
5. Click "Retry" in the dashboard

### Letter Opener not showing emails
Make sure you're using `deliver_now` in test mode:
```ruby
OneWeekEventReminderJob.perform_now(test_mode: true)
```

Or check: [http://localhost:3000/letter_opener](http://localhost:3000/letter_opener)

### Clear everything and start fresh
```bash
# Stop all services
# Press Ctrl+C in the terminal running bin/dev

# Clear Redis
redis-cli FLUSHALL

# Restart
bin/dev
```

---

## 📁 Important Files

### Configuration
- **`config/sidekiq.yml`** - Sidekiq settings (concurrency, queues, Redis connection)
- **`config/initializers/sidekiq.rb`** - Redis connection and ActionMailer integration
- **`config/application.rb`** - Sets Active Job adapter to Sidekiq
- **`config/schedule.rb`** - Cron job schedule using whenever gem

### Jobs
- **`app/jobs/`** - All background job classes
- **`app/jobs/application_job.rb`** - Base class all jobs inherit from

### Process Management
- **`Procfile`** - Production process definitions
- **`Procfile.dev`** - Development process definitions (used by `bin/dev`)

---

## 🎓 Key Concepts

### Synchronous vs Asynchronous

**Synchronous (without background jobs):**
```ruby
# User waits for ALL of this to complete
event.save
send_email_to_100_members  # Takes 30 seconds
# User finally sees success message
```

**Asynchronous (with background jobs):**
```ruby
# User waits only for this
event.save

# This happens instantly (just creates a job in Redis)
SendEmailsJob.perform_later(event.id)

# User sees success immediately
# Emails are sent in background by Sidekiq
```

### Queues

Sidekiq processes jobs from different queues:
- **`default`** - General background jobs
- **`mailers`** - Email delivery jobs (ActionMailer)
- **`low_priority`** - Non-urgent tasks

Jobs in higher-priority queues are processed first.

### Retries

If a job fails, Sidekiq automatically retries it:
- 25 retry attempts over 21 days
- Exponential backoff (waits longer between each retry)
- After 25 failures, job moves to "Dead" queue
- You can manually retry from the web dashboard

---

## 🚀 Production Deployment

### Environment Variables
```bash
# Set Redis URL
REDIS_URL=redis://your-redis-server:6379/0

# Enable SMS in production
ENABLE_SMS=true
```

### Heroku
```bash
# Add Redis addon
heroku addons:create heroku-redis:mini

# The Procfile automatically starts web + sidekiq

# Update crontab for scheduled jobs
heroku run bash
whenever --update-crontab --set environment=production
```

### Manual Deployment
1. Ensure Redis is installed and running
2. Start web server: `bundle exec puma`
3. Start Sidekiq: `bundle exec sidekiq -C config/sidekiq.yml`
4. Set up cron: `whenever --update-crontab --set environment=production`

---

## 📚 Further Reading

- **Sidekiq:** [https://github.com/sidekiq/sidekiq/wiki](https://github.com/sidekiq/sidekiq/wiki)
- **Redis:** [https://redis.io/documentation](https://redis.io/documentation)
- **Active Job:** [https://guides.rubyonrails.org/active_job_basics.html](https://guides.rubyonrails.org/active_job_basics.html)
- **Whenever:** [https://github.com/javan/whenever](https://github.com/javan/whenever)

---

## ✅ Quick Reference

```bash
# Start everything
bin/dev

# View Sidekiq dashboard
open http://localhost:3000/sidekiq

# Rails console commands
OneWeekEventReminderJob.perform_now(test_mode: true)  # Test one-week emails
OneDayEventReminderJob.perform_now(test_mode: true)   # Test one-day emails
Sidekiq::Queue.new.size                                # Check queue
Sidekiq::Stats.new.processed                           # Total processed

# Redis commands
redis-cli ping          # Check if running
redis-cli info          # View stats
redis-cli FLUSHALL      # Clear everything (careful!)

# Cron commands
whenever                           # Preview schedule
whenever --update-crontab          # Update crontab
crontab -l                         # View current crontab
whenever --clear-crontab           # Remove scheduled jobs
```

---

**🎉 That's it!** You now have a robust background job processing system that will keep your app fast and responsive while handling time-consuming tasks behind the scenes.
