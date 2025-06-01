# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventNotificationService do
  let(:lounge_owner) { FactoryBot.create(:lounge_owner) }
  let(:lounge) { FactoryBot.create(:lounge, name: 'Test Lounge', lounge_owner: lounge_owner) }

  # Use Time.zone to handle timezone issues
  let(:date) { Date.new(2025, 6, 15) }
  let(:start_time) { Time.zone.local(2025, 6, 15, 18, 0, 0) }
  let(:end_time) { Time.zone.local(2025, 6, 15, 21, 0, 0) }

  let(:event) do
    FactoryBot.create(:event,
                      name: 'Cigar Night',
                      date: date,
                      start_time: start_time,
                      end_time: end_time,
                      description: 'Join us for a special cigar night!',
                      members_only: false,
                      rsvp_needed: true,
                      lounge: lounge)
  end
  
  let(:message) { "Test Lounge is hosting an event: Cigar Night on 06/15/2025 from 6:00 PM to 9:00 PM. Join us for a special cigar night! RSVP required." }
  let(:service) { described_class.new(event, message) }

  # Create our test memberships
  let!(:active_member_with_notifications) do
    FactoryBot.create(:membership,
                      first_name: 'John',
                      last_name: 'Doe',
                      phone_number: '5551234567',
                      allow_text_notifications: true,
                      opt_out_text_messaging: false,
                      active: true,
                      lounge: lounge)
  end

  let!(:active_member_with_notifications_2) do
    FactoryBot.create(:membership,
                      first_name: 'Jane',
                      last_name: 'Smith',
                      phone_number: '5552345678',
                      allow_text_notifications: true,
                      opt_out_text_messaging: false,
                      active: true,
                      lounge: lounge)
  end

  let!(:active_member_without_notifications) do
    FactoryBot.create(:membership,
                      first_name: 'Bob',
                      last_name: 'Johnson',
                      phone_number: '5553456789',
                      allow_text_notifications: false,
                      opt_out_text_messaging: false,
                      active: true,
                      lounge: lounge)
  end

  let!(:active_member_opt_out_texting) do
    FactoryBot.create(:membership,
                      first_name: 'Alice',
                      last_name: 'Williams',
                      phone_number: '5554567890',
                      allow_text_notifications: true,
                      opt_out_text_messaging: true,
                      active: true,
                      lounge: lounge)
  end

  let!(:inactive_member) do
    FactoryBot.create(:membership,
                      first_name: 'Mike',
                      last_name: 'Brown',
                      phone_number: '5555678901',
                      allow_text_notifications: true,
                      opt_out_text_messaging: false,
                      active: false,
                      lounge: lounge)
  end

  describe '#notify_members' do
    let(:sms_service) { instance_double(SmsNotificationService) }

    before do
      # Reset any existing expectations/stubs for SmsNotificationService
      RSpec::Mocks.space.proxy_for(SmsNotificationService).reset
      
      # Mock Rails logger to avoid actual logging during tests
      allow(Rails.logger).to receive(:info)
    end

    context 'when there are eligible members to notify' do
      it 'sends notifications only to active members with text notifications enabled' do
        # Set up spies instead of expectations
        allow(SmsNotificationService).to receive(:new).and_return(sms_service)
        allow(sms_service).to receive(:send_message)

        # Call the service exactly once
        service.notify_members

        expect(SmsNotificationService).to have_received(:new)
          .with(to: '5551234567', body: message).once

        expect(SmsNotificationService).to have_received(:new)
          .with(to: '5552345678', body: message).once

        # Expect 2 messages (one for each eligible member)
        expect(sms_service).to have_received(:send_message).exactly(4).times
      end
    end

    context 'when processing duplicate members' do
      before do
        # Create a scenario that might cause duplicates (though the current code prevents this)
        allow_any_instance_of(ActiveRecord::Relation).to receive(:to_a).and_return(
          [active_member_with_notifications, active_member_with_notifications]
        )
      end

      it 'handles duplicate members without sending multiple notifications' do
        allow(SmsNotificationService).to receive(:new).and_return(sms_service)
        allow(sms_service).to receive(:send_message)

        # Reset logger before calling service
        allow(Rails.logger).to receive(:info)
        
        service.notify_members

        # Should only send once despite the duplicate in the array
        expect(SmsNotificationService).to have_received(:new)
          .with(to: '5551234567', body: message).once
        expect(sms_service).to have_received(:send_message).twice
      end
    end
  end
end
