# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OneDayEventReminderJob, type: :job do
  describe '#perform' do
    let(:lounge) { create(:lounge) }
    let(:target_date) { 1.day.from_now.to_date }

    context 'when there are events one day away' do
      let!(:event) { create(:event, lounge: lounge, date: target_date) }
      let!(:membership1) { create(:membership, lounge: lounge, active: true, allow_email_notifications: true) }
      let!(:membership2) { create(:membership, lounge: lounge, active: true, allow_email_notifications: true) }
      let!(:membership_no_email) { create(:membership, lounge: lounge, active: true, allow_email_notifications: false) }
      let!(:membership_inactive) { create(:membership, lounge: lounge, active: false, allow_email_notifications: true) }

      it 'sends reminder emails to active members with email notifications enabled' do
        expect(EventReminderMailer).to receive(:one_day_reminder)
          .with(event, membership1)
          .and_return(double(deliver_later: true))

        expect(EventReminderMailer).to receive(:one_day_reminder)
          .with(event, membership2)
          .and_return(double(deliver_later: true))

        expect(EventReminderMailer).not_to receive(:one_day_reminder)
          .with(event, membership_no_email)

        expect(EventReminderMailer).not_to receive(:one_day_reminder)
          .with(event, membership_inactive)

        described_class.new.perform
      end

      it 'logs the number of events found' do
        allow(EventReminderMailer).to receive(:one_day_reminder)
          .and_return(double(deliver_later: true))

        expect(Rails.logger).to receive(:info)
          .with("OneDayEventReminderJob: Found 1 events for #{target_date}")
        expect(Rails.logger).to receive(:info)
          .with("Sending one-day reminders for event: #{event.name} to 2 members")
        expect(Rails.logger).to receive(:info)
          .with('OneDayEventReminderJob completed')

        described_class.new.perform
      end
    end

    context 'when there are no events one day away' do
      it 'does not send any emails' do
        expect(EventReminderMailer).not_to receive(:one_day_reminder)

        described_class.new.perform
      end
    end

    context 'when there are events but no active memberships' do
      let!(:event) { create(:event, lounge: lounge, date: target_date) }

      it 'does not send any emails' do
        expect(EventReminderMailer).not_to receive(:one_day_reminder)

        described_class.new.perform
      end
    end

    context 'when a membership has no email address' do
      let!(:event) { create(:event, lounge: lounge, date: target_date) }
      let!(:membership_no_email) do
        create(:membership, lounge: lounge, active: true, allow_email_notifications: true, email: nil)
      end

      it 'skips that membership' do
        expect(EventReminderMailer).not_to receive(:one_day_reminder)

        described_class.new.perform
      end
    end
  end
end
