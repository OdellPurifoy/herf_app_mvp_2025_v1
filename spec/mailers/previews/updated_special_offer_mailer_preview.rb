# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/updated_special_offer_mailer
class UpdatedSpecialOfferMailerPreview < ActionMailer::Preview
  def notify
    member = Membership.first
    special_offer = SpecialOffer.first
    UpdatedSpecialOfferMailer.with(member: member, special_offer: special_offer).notify
  end
end
