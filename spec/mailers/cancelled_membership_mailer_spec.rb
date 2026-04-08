# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CancelledMembershipMailer, type: :mailer do
  describe 'notify' do
    let(:membership) { FactoryBot.build(:membership) }
    let(:mail) { described_class.with(membership: membership).notify }
    let(:decoded_body) { CGI.unescapeHTML(mail.body.encoded) }

    it 'renders the headers' do
      expect(mail.subject).to eq("Membership cancelled with #{membership.lounge.name}")
      expect(mail.to).to eq([membership.email])
      expect(mail.from).to eq(['info@herfapp.com'])
    end

    it 'renders the body' do
      expect(decoded_body).to match('Membership Cancelled')
      expect(decoded_body).to match("We regret to inform you that your membership with #{membership.lounge.name} has been cancelled.")
      expect(decoded_body).to match('Membership Details')
      expect(decoded_body).to match('Cancellation Notice')
      expect(decoded_body).to match('Powered by Herf')
    end
  end
end
