# Sidekiq Job Processor Setup

This application uses Sidekiq for background job processing, specifically for sending scheduled event reminder emails.

## Prerequisites

- **Redis**: Sidekiq requires Redis to be running
  ```bash
  # Install Redis (macOS)
  brew install redis
  
  # Start Redis
  brew services start redis
  
  # Or run Redis manually
  redis-server
  ```

## Installation

1. Install dependencies:
   ```bash
   bundle install
   ```

2. Make sure Redis is running:
   ```bash
   redis-cli ping
   # Should return: PONG
   ```

## Running in Development

### Option 1: Using Foreman (Recommended)

This will start Rails server, Tailwind watcher, and Sidekiq together:

```bash
bin/dev
```

### Option 2: Running Separately

In separate terminal windows:

```bash
# Terminal 1: Rails server
bin/rails server

# Terminal 2: Tailwind watcher
bin/rails tailwindcss:watch

# Terminal 3: Sidekiq
bundle exec sidekiq -C config/sidekiq.yml
```

## Monitoring Sidekiq

Access the Sidekiq web UI at: [http://localhost:3000/sidekiq](http://localhost:3000/sidekiq)

This dashboard shows:
- Active jobs
- Job history
- Queue statistics
- Failed jobs with retry information

## Event Reminder Jobs

### OneWeekEventReminderJob

Automatically sends email reminders to members one week before events.

**Schedule**: Runs daily at 9:00 AM

**Logic**:
- Finds all events scheduled exactly 7 days from the current date
- Sends reminder emails to active members who:
  - Have `allow_email_notifications` enabled
  - Have a valid email address
  - Belong to the lounge hosting the event

**Manual Trigger** (for testing):
```ruby
# In Rails console
OneWeekEventReminderJob.perform_now

# Or queue it for async processing
OneWeekEventReminderJob.perform_later
```

## Scheduling with Whenever

The application uses the `whenever` gem to manage cron jobs in production.

### Update Crontab

After modifying `config/schedule.rb`:

```bash
# Preview the crontab
whenever

# Update crontab (production)
whenever --update-crontab

# Clear crontab
whenever --clear-crontab
```

### Development Cron Testing

To test cron jobs in development:

```bash
# Set environment to development
whenever --set environment=development --update-crontab

# Check what's scheduled
crontab -l

# Remove when done testing
whenever --clear-crontab
```

## Configuration

### Sidekiq Configuration

- **Config file**: `config/sidekiq.yml`
- **Initializer**: `config/initializers/sidekiq.rb`
- **Concurrency**: 5 threads (adjustable in sidekiq.yml)

### Queues

- `default`: General background jobs
- `mailers`: Email delivery jobs (ActionMailer)
- `low_priority`: Non-urgent tasks

### Redis Configuration

Set the Redis URL via environment variable:

```bash
# .env or environment variables
REDIS_URL=redis://localhost:6379/0
```

## Testing

Run the job specs:

```bash
bundle exec rspec spec/jobs/one_week_event_reminder_job_spec.rb
```

## Production Deployment

### Heroku

1. Add Redis addon:
   ```bash
   heroku addons:create heroku-redis:mini
   ```

2. The `Procfile` will automatically start both web and Sidekiq processes

3. Update crontab:
   ```bash
   # SSH into Heroku
   heroku run bash
   
   # Update crontab
   whenever --update-crontab --set environment=production
   ```

### Other Platforms

Ensure you:
1. Have Redis available
2. Start Sidekiq process alongside your web server
3. Set up cron jobs using `whenever` or your platform's scheduler

## Troubleshooting

### Redis Connection Issues

```bash
# Check if Redis is running
redis-cli ping

# View Redis info
redis-cli info
```

### Sidekiq Not Processing Jobs

1. Check Sidekiq is running:
   ```bash
   ps aux | grep sidekiq
   ```

2. Check the Sidekiq web UI at `/sidekiq`

3. Check logs:
   ```bash
   tail -f log/sidekiq.log
   ```

### Jobs Failing

1. Check the Sidekiq web UI for failed jobs
2. Review error messages
3. Retry failed jobs from the web UI or:
   ```ruby
   # In Rails console
   Sidekiq::RetrySet.new.each(&:retry)
   ```

## Additional Resources

- [Sidekiq Documentation](https://github.com/sidekiq/sidekiq/wiki)
- [Whenever Gem](https://github.com/javan/whenever)
- [Redis Documentation](https://redis.io/documentation)
