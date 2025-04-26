class CancelledMembershipMailer < ApplicationMailer
  default from: 'herf@gmail.com'
  helper :application

  def notify
    @membership = params[:membership]
    mail(to: @membership.email, subject: "Membership cancelled with #{@membership.lounge.name}")
  end
end
