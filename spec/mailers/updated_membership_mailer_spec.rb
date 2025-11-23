# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdatedMembershipMailer, type: :mailer do
  describe 'notify' do
    let(:membership) { FactoryBot.build(:membership) }
    let(:mail) { described_class.with(membership: membership).notify }

    it 'renders the headers' do
      expect(mail.subject).to eq('Update to your membership')
      expect(mail.to).to eq([membership.email])
      expect(mail.from).to eq(['herf@gmail.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match('Membership Updated')
      expect(mail.body.encoded).to match('We wanted to let you know that your membership details have been updated')
      expect(mail.body.encoded).to match('Updated Information')
      expect(mail.body.encoded).to match('Important Notice')
      expect(mail.body.encoded).to match('Powered by Herf')
    end
  end
end
