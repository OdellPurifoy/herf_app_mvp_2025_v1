# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/new_special_offer_mailer
class NewSpecialOfferMailerPreview < ActionMailer::Preview
  def notify
    member = Membership.first
    special_offer = SpecialOffer.first
    NewSpecialOfferMailer.with(member: member, special_offer: special_offer).notify
  end
end
