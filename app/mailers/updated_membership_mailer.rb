# frozen_string_literal: true

class UpdatedMembershipMailer < ApplicationMailer
  default from: 'herf@gmail.com'
  helper :application

  def notify
    @membership = params[:membership]
    mail(to: @membership.email, subject: 'Update to your membership')
  end
end
