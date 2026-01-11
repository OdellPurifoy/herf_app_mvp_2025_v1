# frozen_string_literal: true

class UpdatedMembershipMailer < ApplicationMailer
  helper :application

  def notify
    @membership = params[:membership]
    mail(to: @membership.email, subject: 'Update to your membership')
  end
end
