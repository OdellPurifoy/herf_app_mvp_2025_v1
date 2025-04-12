require 'rails_helper'

RSpec.describe UpdatedSpecialOfferMailer, type: :mailer do
  describe 'notify' do
    let(:member) { FactoryBot.build(:membership) }
    let(:special_offer) { FactoryBot.build(:special_offer) }
    let(:mail) { UpdatedSpecialOfferMailer.with(member: member, special_offer: special_offer).notify }

    it 'renders the headers' do
      expect(mail.subject).to eq("Updated Special Offer: #{special_offer.name}")
      expect(mail.to).to eq([member.email])
      expect(mail.from).to eq(['herf@gmail.com'])
    end
  end
end
