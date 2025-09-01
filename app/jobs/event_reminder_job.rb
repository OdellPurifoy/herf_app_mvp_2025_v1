# frozen_string_literal: true

# app/jobs/event_reminder_job.rb
class EventReminderJob < ApplicationJob
  queue_as :default

  def perform(reminder_type)
    case reminder_type
    when 'one_week'
      send_one_week_reminders
    when 'one_day'
      send_one_day_reminders
    end
  end

  private

  def send_one_week_reminders
    events = Event.joins(:lounge)
                  .where(date: 1.week.from_now.to_date)

    events.each do |event|
      event.lounge.memberships.active.each do |membership|
        EventReminderMailer.one_week_reminder(event, membership).deliver_now
      end
    end
  end

  def send_one_day_reminders
    events = Event.joins(:lounge)
                  .where(date: 1.day.from_now.to_date)
                  .where(lounges: { active: true })

    events.each do |event|
      event.lounge.memberships.active.each do |membership|
        EventReminderMailer.one_day_reminder(event, membership).deliver_now
      end
    end
  end
end
