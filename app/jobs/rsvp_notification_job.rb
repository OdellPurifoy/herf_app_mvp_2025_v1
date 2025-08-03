# frozen_string_literal: true

class RsvpNotificationJob < ApplicationJob
  queue_as :default

  def perform(rsvp_id)
    rsvp = Rsvp.find(rsvp_id)
    return unless rsvp&.membership&.allow_email_notifications?

    RsvpNotificationMailer.with(rsvp: rsvp).rsvp_invitation.deliver_later
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "RSVP with ID #{rsvp_id} not found"
  end
end
