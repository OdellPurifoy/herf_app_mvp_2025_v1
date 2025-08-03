# frozen_string_literal: true

class NewEventMailer < ApplicationMailer
  default from: 'herf@gmail.com'
  helper :application

  def notify
    @member = params[:member]
    @event = params[:event]
    @lounge = @event.lounge

    # If RSVP is needed, find the RSVP for this member
    if @event.rsvp_needed?
      @rsvp = @event.rsvp_for_membership(@member)
      @rsvp_url = rsvp_url(@rsvp.rsvp_token) if @rsvp
    end

    subject = @event.rsvp_needed? ? "RSVP Required: #{@event.name}" : "New Event: #{@event.name}"
    mail(to: @member.email, subject: subject)
  end
end
