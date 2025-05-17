# frozen_string_literal: true

class EventNotificationService
  def initialize(event)
    @event = event
    @lounge = event.lounge
  end

  def notify_members
    eligible_members.each do |member|
      next unless member.allow_text_notifications? && !member.opt_out_text_messaging?

      message_body = build_message
      SmsNotificationService.new(to: member.phone_number, body: message_body).send_message
    end
  end

  private

  def eligible_members
    members = @lounge.memberships.active
    @event.members_only? ? members : members
  end

  def build_message
    message = "#{@lounge.name} is hosting an event: #{@event.name} on #{@event.date.strftime('%m/%d/%Y')} "
    message += "from #{@event.start_time.strftime('%I:%M %p')} to #{@event.end_time.strftime('%I:%M %p')}. "
    message += "#{@event.description}" if @event.description.present?
    message += " This is a members-only event." if @event.members_only?
    message += " RSVP required." if @event.rsvp_needed?
    message
  end
end