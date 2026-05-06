# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MembershipInquiryMailer, type: :mailer do
  describe '#inquiry_notification' do
    let(:lounge_owner) { create(:lounge_owner, email: 'owner@example.com') }
    let(:lounge) { create(:lounge, lounge_owner: lounge_owner) }
    let(:event) { create(:event, lounge: lounge, date: 1.week.from_now) }
    let(:registration) do
      create(:event_registration,
             event: event,
             first_name: 'Jane',
             last_name: 'Smith',
             email: 'jane.smith@example.com',
             phone_number: '5559876543')
    end

    let(:mail) { described_class.inquiry_notification(registration) }

    it 'sends to the lounge owner email' do
      expect(mail.to).to eq(['owner@example.com'])
    end

    it 'includes the registrant name in the subject' do
      expect(mail.subject).to include('Jane Smith')
    end

    it 'includes the registrant contact details in the body' do
      expect(mail.body.encoded).to include('jane.smith@example.com')
      expect(mail.body.encoded).to include('5559876543')
    end

    it 'includes the event name in the body' do
      expect(mail.body.encoded).to include(event.name)
    end

    it 'includes the lounge name in the body' do
      expect(mail.body.encoded).to include(lounge.name)
    end
  end
end
