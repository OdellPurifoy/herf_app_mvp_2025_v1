# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CancelledSpecialOfferMailer, type: :mailer do
  describe 'notify' do
    let(:member) { FactoryBot.build(:membership) }
    let(:special_offer) { FactoryBot.build(:special_offer) }
    let(:mail) { CancelledSpecialOfferMailer.with(member: member, special_offer: special_offer).notify }

    it 'renders the headers' do
      expect(mail.subject).to eq("Special Offer Cancelled: #{special_offer.name}")
      expect(mail.to).to eq([member.email])
      expect(mail.from).to eq(['herf@gmail.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match("Important Update, #{member.first_name}!")
      expect(mail.body.encoded).to match(special_offer.name)
      expect(mail.body.encoded).to match('<strong>Offer Details:</strong>')
    end
  end
end
