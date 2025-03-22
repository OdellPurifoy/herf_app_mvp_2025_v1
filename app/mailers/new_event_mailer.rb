class NewEventMailer < ApplicationMailer
  default from: 'herf@gmail.com'
  helper :application

  def notify
    @member = params[:member]
    @event = params[:event]
    mail(to: @member.email, subject: "New Event: #{@event.name}")
  end
end
