# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sidekiq Cron Jobs', type: :job do
  before(:all) do
    # Load the schedule
    schedule_file = Rails.root.join('config', 'sidekiq_schedule.yml')
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
  end

  describe 'scheduled jobs configuration' do
    it 'loads one_week_event_reminder job' do
      job = Sidekiq::Cron::Job.find('one_week_event_reminder')
      expect(job).not_to be_nil
      expect(job.klass).to eq('OneWeekEventReminderJob')
      expect(job.cron).to eq('0 9 * * *') # Daily at 9 AM
    end

    it 'loads one_day_event_reminder job' do
      job = Sidekiq::Cron::Job.find('one_day_event_reminder')
      expect(job).not_to be_nil
      expect(job.klass).to eq('OneDayEventReminderJob')
      expect(job.cron).to eq('0 18 * * *') # Daily at 6 PM
    end

    it 'has valid cron expressions' do
      Sidekiq::Cron::Job.all.each do |job|
        expect { Fugit.parse(job.cron) }.not_to raise_error
      end
    end
  end

  describe 'job execution' do
    it 'can manually enqueue OneWeekEventReminderJob' do
      job = Sidekiq::Cron::Job.find('one_week_event_reminder')
      result = job.enqueue!
      expect(result).to be_truthy
    end

    it 'can manually enqueue OneDayEventReminderJob' do
      job = Sidekiq::Cron::Job.find('one_day_event_reminder')
      result = job.enqueue!
      expect(result).to be_truthy
    end
  end

  describe 'cron schedule times' do
    it 'one_week_event_reminder runs daily at 9:00 AM' do
      job = Sidekiq::Cron::Job.find('one_week_event_reminder')
      cron = Fugit.parse(job.cron)

      # Get next occurrence from midnight
      base_time = Time.zone.now.beginning_of_day
      next_time = cron.next_time(base_time)

      expect(next_time.hour).to eq(9)
      expect(next_time.min).to eq(0)
    end

    it 'one_day_event_reminder runs daily at 6:00 PM' do
      job = Sidekiq::Cron::Job.find('one_day_event_reminder')
      cron = Fugit.parse(job.cron)

      # Get next occurrence from midnight
      base_time = Time.zone.now.beginning_of_day
      next_time = cron.next_time(base_time)

      expect(next_time.hour).to eq(18)
      expect(next_time.min).to eq(0)
    end
  end
end
