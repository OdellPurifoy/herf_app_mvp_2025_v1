# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NewMembershipMailer, type: :mailer do
  describe 'notify' do
    let(:membership) { FactoryBot.build(:membership) }
    let(:mail) { described_class.with(membership: membership).notify }

    it 'renders the headers' do
      expect(mail.subject).to eq("Welcome to #{membership.lounge.name}")
      expect(mail.to).to eq([membership.email])
      expect(mail.from).to eq(['info@herfapp.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match("Welcome to #{membership.lounge.name}")
      expect(mail.body.encoded).to match('Thank you for joining us!')
    end
  end
end
