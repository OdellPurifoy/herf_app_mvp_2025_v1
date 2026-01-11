# frozen_string_literal: true

class CancelledMembershipMailer < ApplicationMailer
  helper :application

  def notify
    @membership = params[:membership]
    mail(to: @membership.email, subject: "Membership cancelled with #{@membership.lounge.name}")
  end
end
