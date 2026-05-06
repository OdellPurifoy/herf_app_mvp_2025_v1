# frozen_string_literal: true

class EventRegistrationConfirmationJob < ApplicationJob
  queue_as :default

  def perform(registration_id)
    registration = EventRegistration.find_by(id: registration_id)
    return unless registration
    return unless registration.registered?

    EventRegistrationConfirmationMailer.confirmation(registration).deliver_now
  end
end
