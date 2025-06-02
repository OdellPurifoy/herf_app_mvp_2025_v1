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
    it { expect(event).to have_one_attached(:flyer) }
  end

  describe 'validations' do
    it { expect(event).to validate_presence_of(:name) }
    it { expect(event).to validate_presence_of(:event_type) }
    it { expect(event).to validate_presence_of(:date) }
    it { expect(event).to validate_presence_of(:start_time) }
    it { expect(event).to validate_presence_of(:end_time) }
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
        event = FactoryBot.build(:event,
                                 start_time: Time.zone.now,
                                 end_time: Time.zone.now + 1.hour)
        expect(event).to be_valid
      end

      it 'is invalid when end_time is before start_time' do
        # Create a fresh event and explicitly make it invalid
        event = FactoryBot.build(:event,
                                 start_time: Time.zone.now,
                                 end_time: Time.zone.now - 1.hour)
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
end
