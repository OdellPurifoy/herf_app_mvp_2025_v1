# frozen_string_literal: true

class EventDeletionNotificationJob < ApplicationJob
  queue_as :default

  def perform(event_data)
    # Skip SMS in development unless explicitly enabled
    unless Rails.env.production? || ENV['ENABLE_SMS'].present?
      Rails.logger.info "EventDeletionNotificationJob: Skipping SMS in #{Rails.env} environment"
      return
    end

    member_ids = event_data[:member_ids]

    return if member_ids.blank?

    members = Membership.where(id: member_ids)

    return 'No active members found for the lounge' if members.empty?

    members.each do |member|
      next unless member.allow_text_notifications? && !member.opt_out_text_messaging?

      SmsNotificationService.new(to: member.phone_number, body: deletion_message_for(event_data, member)).send_message
    end
  end

  private

  def deletion_message_for(event_data, member)
    <<~SMS
      Hi #{member.first_name},

      We're sorry to inform you that the event "#{event_data[:name]}" originally scheduled for #{event_data[:date].strftime('%B %d')} has been cancelled.

      Reply HELP for help or STOP to unsubscribe.
    SMS
  end
end
