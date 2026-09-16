# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventDeletionNotificationJob, type: :job do # rubocop:disable Metrics/BlockLength
  let(:lounge) { FactoryBot.create(:lounge) }
  let(:event) { FactoryBot.create(:event, lounge: lounge) }
  let!(:sms_member) do
    FactoryBot.create(:membership, lounge: lounge, allow_text_notifications: true, opt_out_text_messaging: false)
  end
  let!(:opted_out_member) do
    FactoryBot.create(:membership, lounge: lounge, allow_text_notifications: true, opt_out_text_messaging: true)
  end
  let(:sms_service) { instance_double(SmsNotificationService, send_message: true) }
  let(:event_data) do
    { id: event.id, name: event.name, date: event.date, member_ids: [sms_member.id, opted_out_member.id] }
  end

  before do
    allow(ENV).to receive(:[]).with('ENABLE_SMS').and_return('true')
    allow(SmsNotificationService).to receive(:new).and_return(sms_service)
  end

  describe '#perform' do
    it 'sends SMS to members who allow text notifications and have not opted out' do
      expect(SmsNotificationService).to receive(:new)
        .with(to: sms_member.phone_number, body: instance_of(String)).and_return(sms_service)

      described_class.perform_now(event_data)
    end

    it 'does not send SMS to members who opted out of text messaging' do
      expect(SmsNotificationService).not_to receive(:new).with(hash_including(to: opted_out_member.phone_number))

      described_class.perform_now(event_data)
    end

    it 'skips SMS outside production unless ENABLE_SMS is set' do
      allow(ENV).to receive(:[]).with('ENABLE_SMS').and_return(nil)
      expect(SmsNotificationService).not_to receive(:new)

      described_class.perform_now(event_data)
    end

    it 'sends nothing when member_ids is blank' do
      expect(SmsNotificationService).not_to receive(:new)

      described_class.perform_now(event_data.merge(member_ids: []))
    end

    it 'never sends email' do
      expect { described_class.perform_now(event_data) }.not_to(change { ActionMailer::Base.deliveries.count })
    end
  end
end
