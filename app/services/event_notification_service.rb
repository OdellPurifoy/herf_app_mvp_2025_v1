# frozen_string_literal: true

class EventNotificationService
  def initialize(event)
    @event = event
    @lounge = event.lounge
  end

  def notify_members
    processed_members = Set.new

    # Cache eligible members in a local variable
    members_to_notify = eligible_members.to_a
    Rails.logger.info "EventNotificationService: Found #{members_to_notify.count} eligible members"

    members_to_notify.each do |member|
      if processed_members.include?(member.id)
        Rails.logger.info "EventNotificationService: Skipping already processed member #{member.id}"
        next
      end

      unless member.allow_text_notifications? && !member.opt_out_text_messaging?
        Rails.logger.info "EventNotificationService: Skipping member #{member.id} due to notification preferences"
        next
      end

      Rails.logger.info "EventNotificationService: Notifying member #{member.id}"
      processed_members.add(member.id)
      message_body = build_message
      SmsNotificationService.new(to: member.phone_number, body: message_body).send_message
    end

    Rails.logger.info "EventNotificationService: Notified #{processed_members.size} members"
  end

  private

  def eligible_members
    @lounge.memberships.active
  end

  def build_message
    message = "#{@lounge.name} is hosting an event: #{@event.name} on #{@event.date.strftime('%m/%d/%Y')} "
    message += "from #{@event.start_time.strftime('%I:%M %p')} to #{@event.end_time.strftime('%I:%M %p')}. "
    message += @event.description.to_s if @event.description.present?
    message += ' This is a members-only event.' if @event.members_only?
    message += ' RSVP required.' if @event.rsvp_needed?
    message
  end
end
