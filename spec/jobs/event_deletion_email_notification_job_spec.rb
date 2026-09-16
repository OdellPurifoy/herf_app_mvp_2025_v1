# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventDeletionEmailNotificationJob, type: :job do # rubocop:disable Metrics/BlockLength
  let(:lounge) { FactoryBot.create(:lounge, name: 'Test Lounge', email: 'lounge@herf.app', phone_number: '5551234567') }
  let(:event) { FactoryBot.create(:event, lounge: lounge, name: 'Cancelled Test Event') }
  let!(:emailable_member) { FactoryBot.create(:membership, lounge: lounge, allow_email_notifications: true) }
  let!(:no_email_member) { FactoryBot.create(:membership, lounge: lounge, allow_email_notifications: false) }
  let(:event_data) do
    {
      id: event.id,
      name: event.name,
      date: event.date,
      start_time: event.start_time,
      lounge_name: lounge.name,
      lounge_email: lounge.email,
      lounge_phone_number: lounge.phone_number,
      member_ids: [emailable_member.id, no_email_member.id]
    }
  end

  def emails_to(member)
    ActionMailer::Base.deliveries.select { |m| m.to == [member.email] }
  end

  describe '#perform' do
    it 'sends the cancellation email to members who allow email notifications' do
      expect { described_class.perform_now(event_data) }.to change { emails_to(emailable_member).count }.by(1)
    end

    it 'does not email members who disabled email notifications' do
      described_class.perform_now(event_data)

      expect(emails_to(no_email_member)).to be_empty
    end

    it 'renders the cancelled event details in the email' do
      described_class.perform_now(event_data)

      mail = emails_to(emailable_member).last
      body = mail.body.encoded
      expect(mail.subject).to eq("Event Cancelled: #{event.name}")
      expect(body).to include(event.name)
      expect(body).to include(event.date.strftime('%A, %B %d, %Y'))
      expect(body).to include(event.start_time.strftime('%I:%M %p'))
      expect(body).to include(lounge.name)
      expect(body).to include(lounge.email)
      expect(body).to include('(555) 123-4567')
    end

    it 'still sends the email when the lounge has no phone number' do
      expect do
        described_class.perform_now(event_data.merge(lounge_phone_number: nil))
      end.to change { emails_to(emailable_member).count }.by(1)
    end

    it 'sends nothing when member_ids is blank' do
      expect do
        described_class.perform_now(event_data.merge(member_ids: []))
      end.not_to(change { ActionMailer::Base.deliveries.count })
    end

    it 'never sends SMS' do
      expect(SmsNotificationService).not_to receive(:new)

      described_class.perform_now(event_data)
    end
  end
end
