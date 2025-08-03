# frozen_string_literal: true

class RsvpNotificationMailer < ApplicationMailer
  default from: 'herf@gmail.com'
  helper :application

  def rsvp_invitation
    @rsvp = params[:rsvp]
    @event = @rsvp.event
    @membership = @rsvp.membership
    @lounge = @event.lounge
    @rsvp_url = rsvp_url(@rsvp.rsvp_token)

    mail(
      to: @membership.email,
      subject: "RSVP Required: #{@event.name} at #{@lounge.name}"
    )
  end
end
