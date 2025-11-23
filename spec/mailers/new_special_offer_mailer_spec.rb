# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NewSpecialOfferMailer, type: :mailer do
  describe 'notify' do
    let(:member) { FactoryBot.build(:membership) }
    let(:special_offer) { FactoryBot.build(:special_offer) }
    let(:mail) { NewSpecialOfferMailer.with(member: member, special_offer: special_offer).notify }

    it 'renders the headers' do
      expect(mail.subject).to eq("New Special Offer: #{special_offer.name}")
      expect(mail.to).to eq([member.email])
      expect(mail.from).to eq(['herf@gmail.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match("Exclusive Offer For You, #{member.first_name}!")
      expect(mail.body.encoded).to match(special_offer.name)
      expect(mail.body.encoded).to match('Special Offer Announced')
      expect(mail.body.encoded).to match('Offer Details')
      expect(mail.body.encoded).to match('Description')
      expect(mail.body.encoded).to match(special_offer.description)
      expect(mail.body.encoded).to match('Powered by Herf')
    end
  end
end
