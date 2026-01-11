# frozen_string_literal: true

class CancelledSpecialOfferMailer < ApplicationMailer
  helper :application

  def notify
    @member = params[:member]
    @special_offer = params[:special_offer]
    mail(to: @member.email, subject: "Special Offer Cancelled: #{@special_offer.name}")
  end
end
