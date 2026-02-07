# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq/cron/web'

# Sidekiq configuration
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

# Set the default queue for ActionMailer
ActionMailer::MailDeliveryJob.queue_as :mailers
