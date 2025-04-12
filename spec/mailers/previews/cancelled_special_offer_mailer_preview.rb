# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/cancelled_special_offer_mailer
class CancelledSpecialOfferMailerPreview < ActionMailer::Preview
  def notify
    member = Membership.first
    special_offer = SpecialOffer.first
    CancelledSpecialOfferMailer.with(member: member, special_offer: special_offer).notify
  end
end
