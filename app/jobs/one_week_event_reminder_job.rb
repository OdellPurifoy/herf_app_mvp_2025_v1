# frozen_string_literal: true

class OneWeekEventReminderJob < ApplicationJob
  queue_as :default

  def perform
    target_date = 7.days.from_now.to_date
    events = Event.where(date: target_date)
    Rails.logger.info "OneWeekEventReminderJob: Found #{events.count} events for #{target_date}"

    return if events.empty?

    events.each do |event|
      # Skip events for lounges without reminders enabled
      next unless event.lounge.lounge_owner.reminders_enabled?

      # Get active memberships for the lounge
      memberships = event.lounge.memberships.active

      # Filter memberships that allow email notifications
      memberships = memberships.where(allow_email_notifications: true)

      Rails.logger.info "Sending one-week reminders for event: #{event.name} to #{memberships.count} members"

      memberships.find_each do |membership|
        # Skip if member has no email
        next if membership.email.blank?

        begin
          EventReminderMailer.one_week_reminder(event, membership).deliver_later
        rescue StandardError => e
          Rails.logger.error "Failed to send one-week reminder to #{membership.email} for event #{event.id}: #{e.message}"
        end
      end
    end

    Rails.logger.info 'OneWeekEventReminderJob completed'
  end
end
