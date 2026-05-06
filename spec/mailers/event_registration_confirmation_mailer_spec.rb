# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventRegistrationConfirmationMailer, type: :mailer do
  describe '#confirmation' do
    let(:registration) { create(:event_registration) }
    let(:mail) { described_class.confirmation(registration) }

    it "sends to the registrant's email" do
      expect(mail.to).to eq([registration.email])
    end

    it 'includes the event name in the subject' do
      expect(mail.subject).to include(registration.event.name)
    end

    it "includes the registrant's first name in the body" do
      expect(mail.body.encoded).to include(registration.first_name)
    end

    it 'includes the event date in the body' do
      expect(mail.body.encoded).to include(registration.event.date.strftime('%B %-d, %Y'))
    end

    it 'includes the registration status URL' do
      expect(mail.body.encoded).to include(registration.registration_token)
    end

    it 'includes the lounge name' do
      expect(mail.body.encoded).to include(registration.event.lounge.name)
    end
  end
end
