# frozen_string_literal: true

# Configure sidekiq-cron scheduled jobs
schedule_file = Rails.root.join('config', 'sidekiq_schedule.yml')

if File.exist?(schedule_file)
  schedule = YAML.load_file(schedule_file)
  Sidekiq::Cron::Job.load_from_hash(schedule)
  Rails.logger.info "Loaded #{schedule.keys.count} sidekiq-cron jobs: #{schedule.keys.join(', ')}"
end
