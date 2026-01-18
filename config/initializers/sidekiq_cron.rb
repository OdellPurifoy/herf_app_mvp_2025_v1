# frozen_string_literal: true

# Configure sidekiq-cron scheduled jobs
if Rails.env.production? || Rails.env.development?
  schedule_file = Rails.root.join('config', 'sidekiq_schedule.yml')

  Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file) if File.exist?(schedule_file)
end
