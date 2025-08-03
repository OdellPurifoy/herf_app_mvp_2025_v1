# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RsvpNotificationJob, type: :job do
  let(:lounge) { FactoryBot.create(:lounge) }
  let(:membership) { FactoryBot.create(:membership, lounge: lounge, allow_email_notifications: true) }
  let(:event) do
    FactoryBot.create(:event,
                      lounge: lounge,
                      date: 1.week.from_now.to_date,
                      start_time: Time.zone.today + 1.week + 7.hours,
                      end_time: Time.zone.today + 1.week + 9.hours,
                      rsvp_needed: true)
  end

  let(:rsvp) do
    # Ensure membership exists before event creation
    membership
    # Create event (this should auto-create RSVPs)
    created_event = event
    # Find the RSVP that should have been created
    created_event.rsvp_for_membership(membership)
  end

  describe '#perform' do
    it 'sends an RSVP invitation email when notifications are enabled' do
      expect do
        RsvpNotificationJob.perform_now(rsvp.id)
      end.to have_enqueued_mail(RsvpNotificationMailer, :rsvp_invitation)
    end

    it 'does not send email when notifications are disabled' do
      membership.update!(allow_email_notifications: false)

      expect do
        RsvpNotificationJob.perform_now(rsvp.id)
      end.not_to have_enqueued_mail(RsvpNotificationMailer, :rsvp_invitation)
    end

    it 'handles missing RSVP gracefully' do
      expect do
        RsvpNotificationJob.perform_now(999_999)
      end.not_to raise_error
    end
  end
end
