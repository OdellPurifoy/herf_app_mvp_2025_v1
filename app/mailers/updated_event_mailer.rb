# frozen_string_literal: true

class UpdatedEventMailer < ApplicationMailer
  default from: 'herf@gmail.com'
  helper :application

  def notify
    @member = params[:member]
    @event = params[:event]
    @changed_attributes = params[:changed_attributes] || []
    mail(to: @member.email, subject: "Event Update: #{@event.name}")
  end
end
