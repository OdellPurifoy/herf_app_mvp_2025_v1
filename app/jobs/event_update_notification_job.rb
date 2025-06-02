# frozen_string_literal: true

class EventUpdateNotificationJob < ApplicationJob
  queue_as :default

  def perform(event_id)
    begin
      event = Event.find(event_id)
    rescue ActiveRecord::RecordNotFound
      puts 'Event Not Found'
      return
    end

    members = event.lounge.memberships.active

    return 'No active members found for the lounge' if members.empty?

    members.each do |member|
      next unless member.allow_text_notifications? && !member.opt_out_text_messaging?

      SmsNotificationService.new(to: member.phone_number, body: update_message_for(event, member)).send_message
    end
  end

  private

  def update_message_for(event, member)
    <<~SMS
      Hi #{member.first_name},

      The event "#{event.name}" has been updated:

      Date: #{event.date.strftime('%B %d, %Y')}
      Time: #{event.start_time.strftime('%I:%M %p')} - #{event.end_time.strftime('%I:%M %p')}
      Capacity: #{event.capacity} people

      Description:
      #{event.description&.truncate(160)}

      Reply HELP for help or STOP to unsubscribe.
    SMS
  end
end
