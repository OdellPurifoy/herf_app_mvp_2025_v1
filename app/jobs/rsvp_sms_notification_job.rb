# frozen_string_literal: true

class RsvpSmsNotificationJob < ApplicationJob
  queue_as :default

  def perform(rsvp_id)
    # Skip SMS in development unless explicitly enabled
    unless Rails.env.production? || ENV['ENABLE_SMS'].present?
      Rails.logger.info "RsvpSmsNotificationJob: Skipping SMS in #{Rails.env} environment"
      return
    end

    rsvp = Rsvp.find(rsvp_id)
    return unless rsvp&.membership&.allow_text_notifications?
    return if rsvp.membership.phone_number.blank?

    event = rsvp.event
    lounge = event.lounge
    rsvp_url = Rails.application.routes.url_helpers.rsvp_url(
      rsvp.rsvp_token,
      host: Rails.application.config.action_mailer.default_url_options[:host]
    )

    message = build_sms_message(rsvp, event, lounge, rsvp_url)

    SmsNotificationService.new(
      to: rsvp.membership.phone_number,
      body: message
    ).send_message
  end

  private

  def build_sms_message(rsvp, event, lounge, rsvp_url)
    <<~SMS
      🎯 RSVP Required for #{lounge.name}

      Hi #{rsvp.membership.first_name}! You're invited to:

      📅 #{event.name}
      🗓 #{event.date.strftime('%a, %b %d')} at #{event.start_time.strftime('%I:%M %p')}

      Please confirm your attendance:
      #{rsvp_url}

      Link expires 1 hour before the event.
    SMS
  end
end
