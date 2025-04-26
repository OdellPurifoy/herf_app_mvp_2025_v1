# frozen_string_literal: true

class NewMembershipMailer < ApplicationMailer
  default from: 'herf@gmail.com'
  helper :application

  def notify
    @membership = params[:membership]
    mail(to: @membership.email, subject: "Welcome to #{@membership.lounge.name}")
  end
end
