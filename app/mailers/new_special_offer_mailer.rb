class NewSpecialOfferMailer < ApplicationMailer
  default from: 'herf@gmail.com'
  helper :application

  def notify
    @member = params[:member]
    @special_offer = params[:special_offer]
    mail(to: @member.email, subject: "New Special Offer: #{@special_offer.name}")
  end
end
