# frozen_string_literal: true

class EventRegistrationConfirmationMailer < ApplicationMailer
  def confirmation(registration)
    @registration = registration
    @event = registration.event
    @lounge = @event.lounge
    @status_url = registration_status_url(@registration.registration_token)

    mail(
      to: @registration.email,
      subject: "You're registered for #{@event.name}!"
    )
  end
end
