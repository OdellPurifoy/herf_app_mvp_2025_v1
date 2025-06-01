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
      end_time: Time.zone.now + 3.hours
    )
  end

  describe 'ActiveRecord associations' do
    it { expect(event).to belong_to(:lounge) }
  end

  describe 'validations' do
    it { expect(event).to validate_presence_of(:name) }
    it { expect(event).to validate_presence_of(:event_type) }
    it { expect(event).to validate_presence_of(:date) }
    it { expect(event).to validate_presence_of(:start_time) }
    it { expect(event).to validate_presence_of(:end_time) }
  end

  describe 'callbacks' do
    let(:notification_service) { instance_double(EventNotificationService) }
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
    
    before do
      allow(EventNotificationService).to receive(:new).and_return(notification_service)
      allow(notification_service).to receive(:notify_members)
    end

    describe 'after_create' do
      it 'sends notifications to members when an event is created' do
        event = Event.create!(valid_event_attributes)
        
        expect(EventNotificationService).to have_received(:new) do |event_arg, message|
          expect(event_arg).to eq(event)
          expect(message).to include("Test Lounge is hosting an event: Test Event")
          expect(message).to include("Event description")
        end
        
        expect(notification_service).to have_received(:notify_members).once
      end
    end
    
    describe 'after_update' do
      it 'uses the updated_event_message method when an event is updated' do
        event = Event.create!(valid_event_attributes)
        
        allow(EventNotificationService).to receive(:new).and_return(notification_service)
        allow(notification_service).to receive(:notify_members)
        
        allow(event).to receive(:updated_event_message).and_call_original
        
        event.update!(name: 'Updated Event Name')
        
        expect(event).to have_received(:updated_event_message)
        expect(notification_service).to have_received(:notify_members).twice
      end
    end
  end

  describe 'instance methods' do
    describe '#end_time_after_start_time' do
      it 'is valid when end_time is after start_time' do
        # Create a fresh event to avoid test pollution
        event = FactoryBot.build(:event, 
          start_time: Time.zone.now,
          end_time: Time.zone.now + 1.hour
        )
        expect(event).to be_valid
      end

      it 'is invalid when end_time is before start_time' do
        # Create a fresh event and explicitly make it invalid
        event = FactoryBot.build(:event,
          start_time: Time.zone.now,
          end_time: Time.zone.now - 1.hour
        )
        expect(event).not_to be_valid
        expect(event.errors[:end_time]).to include("must be after the start time")
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
        expect(event.errors[:date]).to include("must be in the future")
      end
    end
    
    describe 'message formatting' do
      let(:test_event) do
        FactoryBot.build(:event,
          name: 'Test Event',
          date: Date.new(2025, 6, 15),
          start_time: Time.zone.local(2025, 6, 15, 18, 0, 0),
          end_time: Time.zone.local(2025, 6, 15, 21, 0, 0),
          description: 'Event description',
          capacity: 50,
          entry_fee: 25.00,
          members_only: true,
          rsvp_needed: true,
          lounge: lounge
        )
      end
      
      it 'formats new event messages correctly' do
        # Use send to test private method
        message = test_event.send(:new_event_message)
        
        expect(message).to include("Test Lounge is hosting an event: Test Event")
        expect(message).to include("on 06/15/2025")
        expect(message).to include("from 06:00 PM to 09:00 PM")
        expect(message).to include("Event description")
        expect(message).to include("Capacity: 50")
        expect(message).to include("Entry fee: $25.00")
        expect(message).to include("This is a members-only event")
        expect(message).to include("RSVP required")
      end
      
      it 'formats updated event messages correctly' do
        test_event.save!
        
        # Store original name for assertion
        original_name = test_event.name
        
        # Update the event name
        test_event.name = "Updated Event Name"
        test_event.save!
        
        # Use send to test private method
        message = test_event.send(:updated_event_message)
        
        # Less specific expectations to accommodate format changes
        expect(message).to include("Updated Event Name")
        expect(message).to include("06/15/2025")
        expect(message).to include("'#{original_name}'")
        expect(message).to include("'Updated Event Name'")
      end
    end
  end
end
