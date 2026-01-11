# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CancelledMembershipMailer, type: :mailer do
  describe 'notify' do
    let(:membership) { FactoryBot.build(:membership) }
    let(:mail) { described_class.with(membership: membership).notify }

    it 'renders the headers' do
      expect(mail.subject).to eq("Membership cancelled with #{membership.lounge.name}")
      expect(mail.to).to eq([membership.email])
      expect(mail.from).to eq(['info@herfapp.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match('Membership Cancelled')
      expect(mail.body.encoded).to match("We regret to inform you that your membership with #{membership.lounge.name} has been cancelled.")
      expect(mail.body.encoded).to match('Membership Details')
      expect(mail.body.encoded).to match('Cancellation Notice')
      expect(mail.body.encoded).to match('Powered by Herf')
    end
  end
end
