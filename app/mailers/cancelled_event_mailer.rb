# frozen_string_literal: true

class CancelledEventMailer < ApplicationMailer
  default from: 'herf@gmail.com'
  helper :application

  def notify
    @member = params[:member]
    @event = params[:event]
    mail(to: @member.email, subject: "Event Cancelled: #{@event.name}")
  end
end
