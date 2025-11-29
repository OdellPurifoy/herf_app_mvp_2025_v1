# frozen_string_literal: true

class OneWeekEventReminderJob < ApplicationJob
  queue_as :default

  def perform(test_mode: false)
    if test_mode
      # TEST MODE: Send to any upcoming event for testing
      Rails.logger.info 'OneWeekEventReminderJob: Running in TEST MODE'
      events = Event.upcoming.limit(5)
      Rails.logger.info "OneWeekEventReminderJob: Found #{events.count} upcoming events for testing"
    else
      # PRODUCTION MODE: Find all events that are exactly 7 days from today
      target_date = 7.days.from_now.to_date
      events = Event.where(date: target_date)
      Rails.logger.info "OneWeekEventReminderJob: Found #{events.count} events for #{target_date}"
    end

    return if events.empty?

    events.each do |event|
      # Get active memberships for the lounge
      memberships = event.lounge.memberships.active

      # Filter memberships that allow email notifications
      memberships = memberships.where(allow_email_notifications: true)

      Rails.logger.info "Sending one-week reminders for event: #{event.name} to #{memberships.count} members"

      memberships.find_each do |membership|
        # Skip if member has no email
        next if membership.email.blank?

        begin
          # Use deliver_now in test mode so letter_opener shows emails immediately
          if test_mode
            EventReminderMailer.one_week_reminder(event, membership).deliver_now
          else
            EventReminderMailer.one_week_reminder(event, membership).deliver_later
          end
        rescue StandardError => e
          Rails.logger.error "Failed to send one-week reminder to #{membership.email} for event #{event.id}: #{e.message}"
        end
      end
    end

    Rails.logger.info 'OneWeekEventReminderJob completed'
  end
end
