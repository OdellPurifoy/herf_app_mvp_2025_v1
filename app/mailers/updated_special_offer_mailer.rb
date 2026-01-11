# frozen_string_literal: true

class UpdatedSpecialOfferMailer < ApplicationMailer
  helper :application

  def notify
    @member = params[:member]
    @special_offer = params[:special_offer]
    mail(to: @member.email, subject: "Updated Special Offer: #{@special_offer.name}")
  end
end
