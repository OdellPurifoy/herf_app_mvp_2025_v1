# frozen_string_literal: true

class MembershipInquiryMailer < ApplicationMailer
  def inquiry_notification(event_registration)
    @registration = event_registration
    @event = @registration.event
    @lounge = @event.lounge
    @lounge_owner = @lounge.lounge_owner

    mail(
      to: @lounge_owner.email,
      subject: "New membership inquiry from #{@registration.full_name}"
    )
  end
end
