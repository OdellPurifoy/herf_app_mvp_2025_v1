# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OneWeekEventReminderJob, type: :job do
  describe '#perform' do
    let(:lounge) { create(:lounge) }
    let(:target_date) { 7.days.from_now.to_date }

    context 'when there are events one week away' do
      let!(:event) { create(:event, lounge: lounge, date: target_date) }
      let!(:membership1) { create(:membership, lounge: lounge, active: true, allow_email_notifications: true) }
      let!(:membership2) { create(:membership, lounge: lounge, active: true, allow_email_notifications: true) }
      let!(:membership_no_email) { create(:membership, lounge: lounge, active: true, allow_email_notifications: false) }
      let!(:membership_inactive) { create(:membership, lounge: lounge, active: false, allow_email_notifications: true) }

      it 'sends reminder emails to active members with email notifications enabled' do
        expect(EventReminderMailer).to receive(:one_week_reminder)
          .with(event, membership1)
          .and_return(double(deliver_later: true))

        expect(EventReminderMailer).to receive(:one_week_reminder)
          .with(event, membership2)
          .and_return(double(deliver_later: true))

        expect(EventReminderMailer).not_to receive(:one_week_reminder)
          .with(event, membership_no_email)

        expect(EventReminderMailer).not_to receive(:one_week_reminder)
          .with(event, membership_inactive)

        described_class.new.perform
      end

      it 'logs the number of events found' do
        allow(EventReminderMailer).to receive(:one_week_reminder)
          .and_return(double(deliver_later: true))

        expect(Rails.logger).to receive(:info)
          .with("OneWeekEventReminderJob: Found 1 events for #{target_date}")
        expect(Rails.logger).to receive(:info)
          .with("Sending one-week reminders for event: #{event.name} to 2 members")
        expect(Rails.logger).to receive(:info)
          .with('OneWeekEventReminderJob completed')

        described_class.new.perform
      end
    end

    context 'when there are no events one week away' do
      it 'does not send any emails' do
        expect(EventReminderMailer).not_to receive(:one_week_reminder)

        described_class.new.perform
      end
    end

    context 'when there are events but no active memberships' do
      let!(:event) { create(:event, lounge: lounge, date: target_date) }

      it 'does not send any emails' do
        expect(EventReminderMailer).not_to receive(:one_week_reminder)

        described_class.new.perform
      end
    end

    context 'when a membership has no email address' do
      let!(:event) { create(:event, lounge: lounge, date: target_date) }
      let!(:membership_no_email) do
        create(:membership, lounge: lounge, active: true, allow_email_notifications: true, email: nil)
      end

      it 'skips that membership' do
        expect(EventReminderMailer).not_to receive(:one_week_reminder)

        described_class.new.perform
      end
    end

    context 'when lounge owner has Robusto subscription' do
      let(:lounge_owner) { create(:lounge_owner, :with_stripe_customer) }
      let(:lounge) { create(:lounge, lounge_owner: lounge_owner) }
      let!(:event) { create(:event, lounge: lounge, date: target_date) }
      let!(:membership) { create(:membership, lounge: lounge, active: true, allow_email_notifications: true) }

      before do
        customer = lounge_owner.payment_processor
        customer.subscriptions.create!(
          name: 'robusto_monthly',
          processor_id: 'sub_robusto',
          processor_plan: 'price_robusto_monthly',
          status: 'active',
          current_period_start: Time.current,
          current_period_end: 1.month.from_now
        )
      end

      it 'does not send reminder emails for Robusto plan events' do
        expect(EventReminderMailer).not_to receive(:one_week_reminder)

        described_class.new.perform
      end
    end

    context 'when lounge owner has Churchill subscription' do
      let(:lounge_owner) { create(:lounge_owner, :with_stripe_customer) }
      let(:lounge) { create(:lounge, lounge_owner: lounge_owner) }
      let!(:event) { create(:event, lounge: lounge, date: target_date) }
      let!(:membership) { create(:membership, lounge: lounge, active: true, allow_email_notifications: true) }

      before do
        customer = lounge_owner.payment_processor
        customer.subscriptions.create!(
          name: 'churchill_monthly',
          processor_id: 'sub_churchill',
          processor_plan: 'price_churchill_monthly',
          status: 'active',
          current_period_start: Time.current,
          current_period_end: 1.month.from_now
        )
      end

      it 'sends reminder emails for Churchill plan events' do
        expect(EventReminderMailer).to receive(:one_week_reminder)
          .with(event, membership)
          .and_return(double(deliver_later: true))

        described_class.new.perform
      end
    end
  end
end
