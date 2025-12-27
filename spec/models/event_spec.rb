# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Event, type: :model do
  it 'has a valid factory' do
    event = FactoryBot.build(:event)
    expect(event).to be_valid
  end

  let(:lounge) { FactoryBot.create(:lounge, name: 'Test Lounge') }
  let(:event) do
    FactoryBot.build(:event,
                     lounge: lounge,
                     start_time: Time.zone.now + 1.hour,
                     end_time: Time.zone.now + 3.hours)
  end

  describe 'ActiveRecord associations' do
    it { expect(event).to belong_to(:lounge) }
    it { expect(event).to have_many(:rsvps).dependent(:destroy) }
    it { expect(event).to have_one_attached(:flyer) }
  end

  describe 'validations' do
    it { expect(event).to validate_presence_of(:name) }
    it { expect(event).to validate_presence_of(:event_type) }
    it { expect(event).to validate_presence_of(:date) }
    it { expect(event).to validate_presence_of(:start_time) }
    it { expect(event).to validate_presence_of(:end_time) }

    context 'when the event is virtual' do
      let(:virtual_event) { FactoryBot.build(:event, virtual: true, virtual_url: nil) }

      it 'is not a valid virtual event without a virtual_url' do
        expect(virtual_event.valid?).to eq false
      end
    end
  end

  describe 'callbacks' do
    let(:valid_event_attributes) do
      {
        name: 'Test Event',
        event_type: 'Cigar Brand Event',
        date: Date.today + 1.day,
        start_time: Time.zone.today + 1.day + 2.hours,
        end_time: Time.zone.today + 1.day + 5.hours,
        description: 'Event description',
        lounge: lounge
      }
    end

    describe 'after_create' do
      it 'enqueues an EventCreationNotificationJob when an event is created' do
        expect do
          Event.create!(valid_event_attributes)
        end.to have_enqueued_job(EventCreationNotificationJob)
      end

      it 'passes the event ID and create action to the job' do
        event = Event.create!(valid_event_attributes)
        expect(EventCreationNotificationJob).to have_been_enqueued.with(event.id)
      end
    end

    describe 'after_update' do
      it 'enqueues an EventUpdateNotificationJob when an event is updated' do
        event = Event.create!(valid_event_attributes)

        expect do
          event.update!(name: 'Updated Event Name')
        end.to have_enqueued_job(EventUpdateNotificationJob)
      end

      it 'passes the event ID to the job' do
        event = Event.create!(valid_event_attributes)
        event.update!(name: 'Updated Event Name')

        expect(EventUpdateNotificationJob).to have_been_enqueued.with(event.id)
      end
    end

    describe 'after_destroy' do
      it 'enqueues an EventDeletionNotificationJob when an event is deleted' do
        event = Event.create!(valid_event_attributes)

        expect do
          event.destroy
        end.to have_enqueued_job(EventDeletionNotificationJob)
      end

      it 'passes event data to the job' do
        event = Event.create!(valid_event_attributes)

        # Create some active members for the lounge
        allow(lounge).to receive_message_chain(:memberships, :active, :pluck).and_return([1, 2, 3])

        event_data = {
          id: event.id,
          name: event.name,
          date: event.date,
          member_ids: [1, 2, 3]
        }

        expect do
          event.destroy
        end.to have_enqueued_job(EventDeletionNotificationJob).with(event_data)
      end
    end
  end

  describe 'instance methods' do
    describe '#end_time_after_start_time' do
      it 'is valid when end_time is after start_time' do
        # Create a fresh event to avoid test pollution
        start_time = Time.zone.parse('2025-08-15 14:00:00')
        end_time = Time.zone.parse('2025-08-15 16:00:00')
        event = FactoryBot.build(:event,
                                 start_time: start_time,
                                 end_time: end_time)
        expect(event).to be_valid
      end

      it 'is invalid when end_time is before start_time' do
        # Create a fresh event and explicitly make it invalid
        start_time = Time.zone.parse('2025-08-15 16:00:00')
        end_time = Time.zone.parse('2025-08-15 14:00:00')
        event = FactoryBot.build(:event,
                                 start_time: start_time,
                                 end_time: end_time)
        expect(event).not_to be_valid
        expect(event.errors[:end_time]).to include('must be after the start time')
      end
    end

    describe '#date_not_in_past' do
      it 'is valid when date is in the future' do
        event = FactoryBot.build(:event, date: Date.today + 1.day)
        expect(event).to be_valid
      end

      it 'is invalid when date is in the past' do
        event = FactoryBot.build(:event, date: Date.today - 1.day)
        expect(event).not_to be_valid
        expect(event.errors[:date]).to include('must be in the future')
      end
    end
  end

  describe 'RSVP creation' do
    let!(:active_membership1) { FactoryBot.create(:membership, lounge: lounge, active: true) }
    let!(:active_membership2) { FactoryBot.create(:membership, lounge: lounge, active: true) }
    let!(:inactive_membership) { FactoryBot.create(:membership, :inactive, lounge: lounge) }

    context 'when creating an event with rsvp_needed: true' do
      it 'creates RSVPs for all active members' do
        expect do
          Event.create!(
            name: 'RSVP Event',
            event_type: 'Wine Tasting',
            date: 1.week.from_now.to_date,
            start_time: Time.zone.today + 1.week + 7.hours,
            end_time: Time.zone.today + 1.week + 9.hours,
            rsvp_needed: true,
            lounge: lounge
          )
        end.to change(Rsvp, :count).by(2)
      end

      it 'does not create RSVPs for inactive members' do
        event = Event.create!(
          name: 'RSVP Event',
          event_type: 'Wine Tasting',
          date: 1.week.from_now.to_date,
          start_time: Time.zone.today + 1.week + 7.hours,
          end_time: Time.zone.today + 1.week + 9.hours,
          rsvp_needed: true,
          lounge: lounge
        )

        expect(event.rsvps.joins(:membership).where(memberships: { active: false })).to be_empty
      end

      it 'creates RSVPs with correct default values' do
        event = Event.create!(
          name: 'RSVP Event',
          event_type: 'Wine Tasting',
          date: 1.week.from_now.to_date,
          start_time: Time.zone.today + 1.week + 7.hours,
          end_time: Time.zone.today + 1.week + 9.hours,
          rsvp_needed: true,
          lounge: lounge
        )

        rsvp = event.rsvps.first
        expect(rsvp.status).to eq('pending')
        expect(rsvp.guest_count).to eq(1)
        expect(rsvp.rsvp_token).to be_present
        expect(rsvp.expires_at).to be_within(1.minute).of(event.event_date - 1.hour)
      end
    end

    context 'when creating an event with rsvp_needed: false' do
      it 'does not create any RSVPs' do
        expect do
          Event.create!(
            name: 'No RSVP Event',
            event_type: 'Other',
            date: 1.week.from_now.to_date,
            start_time: Time.zone.today + 1.week + 7.hours,
            end_time: Time.zone.today + 1.week + 9.hours,
            rsvp_needed: false,
            lounge: lounge
          )
        end.not_to change(Rsvp, :count)
      end
    end

    context 'when updating an event to enable RSVP' do
      let!(:existing_event) do
        Event.create!(
          name: 'Existing Event',
          event_type: 'Other',
          date: 1.week.from_now.to_date,
          start_time: Time.zone.today + 1.week + 7.hours,
          end_time: Time.zone.today + 1.week + 9.hours,
          rsvp_needed: false,
          lounge: lounge
        )
      end

      it 'creates RSVPs when rsvp_needed is changed to true' do
        expect do
          existing_event.update!(rsvp_needed: true)
        end.to change(Rsvp, :count).by(2)
      end

      it 'does not create duplicate RSVPs if RSVPs already exist' do
        existing_event.update!(rsvp_needed: true)

        expect do
          existing_event.update!(name: 'Updated Name')
        end.not_to change(Rsvp, :count)
      end
    end

    context 'when updating an event to disable RSVP' do
      let!(:rsvp_event) do
        Event.create!(
          name: 'RSVP Event',
          event_type: 'Wine Tasting',
          date: 1.week.from_now.to_date,
          start_time: Time.zone.today + 1.week + 7.hours,
          end_time: Time.zone.today + 1.week + 9.hours,
          rsvp_needed: true,
          lounge: lounge
        )
      end

      it 'does not create additional RSVPs when rsvp_needed is changed to false' do
        expect do
          rsvp_event.update!(rsvp_needed: false)
        end.not_to change(Rsvp, :count)
      end
    end
  end

  describe 'RSVP helper methods' do
    let!(:event_with_rsvps) do
      Event.create!(
        name: 'RSVP Event',
        event_type: 'Wine Tasting',
        date: 1.week.from_now.to_date,
        start_time: Time.zone.today + 1.week + 7.hours,
        end_time: Time.zone.today + 1.week + 9.hours,
        rsvp_needed: true,
        capacity: 20,
        lounge: lounge
      )
    end

    let!(:membership1) { FactoryBot.create(:membership, lounge: lounge) }
    let!(:membership2) { FactoryBot.create(:membership, lounge: lounge) }
    let!(:membership3) { FactoryBot.create(:membership, lounge: lounge) }

    before do
      # Create RSVPs with different statuses
      FactoryBot.create(:rsvp, :attending, event: event_with_rsvps, membership: membership1, guest_count: 2)
      FactoryBot.create(:rsvp, :declined, event: event_with_rsvps, membership: membership2)
      FactoryBot.create(:rsvp, event: event_with_rsvps, membership: membership3) # pending
    end

    describe '#total_confirmed_attendees' do
      it 'returns the sum of guest_count for attending RSVPs' do
        expect(event_with_rsvps.total_confirmed_attendees).to eq(2)
      end
    end

    describe '#pending_rsvps_count' do
      it 'returns the count of pending RSVPs' do
        expect(event_with_rsvps.pending_rsvps_count).to eq(1)
      end
    end

    describe '#attending_rsvps_count' do
      it 'returns the count of attending RSVPs' do
        expect(event_with_rsvps.attending_rsvps_count).to eq(1)
      end
    end

    describe '#declined_rsvps_count' do
      it 'returns the count of declined RSVPs' do
        expect(event_with_rsvps.declined_rsvps_count).to eq(1)
      end
    end

    describe '#capacity_remaining' do
      it 'returns the remaining capacity' do
        expect(event_with_rsvps.capacity_remaining).to eq(18)
      end

      it 'returns nil when capacity is not set' do
        event_with_rsvps.update!(capacity: nil)
        expect(event_with_rsvps.capacity_remaining).to be_nil
      end
    end

    describe '#at_capacity?' do
      it 'returns false when not at capacity' do
        expect(event_with_rsvps.at_capacity?).to be false
      end

      it 'returns true when at capacity' do
        event_with_rsvps.update!(capacity: 2)
        expect(event_with_rsvps.at_capacity?).to be true
      end

      it 'returns false when capacity is not set' do
        event_with_rsvps.update!(capacity: nil)
        expect(event_with_rsvps.at_capacity?).to be false
      end
    end

    describe '#rsvp_summary' do
      it 'returns nil for events without RSVP' do
        no_rsvp_event = FactoryBot.create(:event, rsvp_needed: false, lounge: lounge)
        expect(no_rsvp_event.rsvp_summary).to be_nil
      end

      it 'returns correct RSVP summary' do
        summary = event_with_rsvps.rsvp_summary
        expect(summary).to eq({
                                total_invites: 3,
                                pending: 1,
                                attending: 1,
                                declined: 1,
                                total_guests: 2,
                                capacity_remaining: 18
                              })
      end
    end

    describe '#rsvp_response_rate' do
      it 'returns 0 for events without RSVP' do
        no_rsvp_event = FactoryBot.create(:event, rsvp_needed: false, lounge: lounge)
        expect(no_rsvp_event.rsvp_response_rate).to eq(0)
      end

      it 'calculates correct response rate' do
        # 2 responded out of 3 = 66.7%
        expect(event_with_rsvps.rsvp_response_rate).to eq(66.7)
      end

      it 'returns 0 when no RSVPs exist' do
        event_with_rsvps.rsvps.destroy_all
        expect(event_with_rsvps.rsvp_response_rate).to eq(0)
      end
    end

    describe '#rsvp_for_membership' do
      it 'returns the RSVP for a specific membership' do
        rsvp = event_with_rsvps.rsvp_for_membership(membership1)
        expect(rsvp).to be_present
        expect(rsvp.membership).to eq(membership1)
      end

      it 'returns nil when no RSVP exists for membership' do
        other_membership = FactoryBot.create(:membership, lounge: lounge)
        rsvp = event_with_rsvps.rsvp_for_membership(other_membership)
        expect(rsvp).to be_nil
      end
    end
  end

  describe 'subscription plan validations' do
    context 'with Robusto subscription' do
      let(:lounge_owner) { create(:lounge_owner, :with_stripe_customer) }
      let(:lounge) { create(:lounge, lounge_owner: lounge_owner) }

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

      context 'when event count is below monthly limit' do
        before do
          create(:event, lounge: lounge, date: 2.weeks.from_now.to_date)
        end

        it 'allows creating a new event in the same month' do
          new_event = build(:event, lounge: lounge, date: 3.weeks.from_now.to_date)
          expect(new_event).to be_valid
        end
      end

      context 'when event count equals monthly limit' do
        before do
          create(:event, lounge: lounge, date: 2.weeks.from_now.to_date)
          create(:event, lounge: lounge, date: 3.weeks.from_now.to_date)
        end

        it 'does not allow creating a new event in the same month' do
          new_event = build(:event, lounge: lounge, date: 4.weeks.from_now.to_date)
          expect(new_event).not_to be_valid
          expect(new_event.errors[:base]).to include('Event limit reached. Your Robusto plan allows up to 2 events per month. Please upgrade to create more events.')
        end
      end

      context 'when event count equals limit but in different months' do
        before do
          create(:event, lounge: lounge, date: 2.weeks.from_now.to_date)
          create(:event, lounge: lounge, date: 3.weeks.from_now.to_date)
        end

        it 'allows creating a new event in a different month' do
          new_event = build(:event, lounge: lounge, date: 2.months.from_now.to_date)
          expect(new_event).to be_valid
        end
      end

      context 'when event count exceeds monthly limit' do
        before do
          # Create exactly at the limit
          create(:event, lounge: lounge, date: 2.weeks.from_now.to_date)
          create(:event, lounge: lounge, date: 3.weeks.from_now.to_date)
        end

        it 'does not allow creating a new event in the same month' do
          new_event = build(:event, lounge: lounge, date: 4.weeks.from_now.to_date + 1.day)
          expect(new_event).not_to be_valid
          expect(new_event.errors[:base]).to include('Event limit reached. Your Robusto plan allows up to 2 events per month. Please upgrade to create more events.')
        end
      end
    end

    context 'with Churchill subscription' do
      let(:lounge_owner) { create(:lounge_owner, :with_stripe_customer) }
      let(:lounge) { create(:lounge, lounge_owner: lounge_owner) }

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

      context 'when creating many events in the same month' do
        before do
          create_list(:event, 10, lounge: lounge, date: 2.weeks.from_now.to_date)
        end

        it 'allows creating unlimited events' do
          new_event = build(:event, lounge: lounge, date: 3.weeks.from_now.to_date)
          expect(new_event).to be_valid
        end
      end
    end
  end
end
