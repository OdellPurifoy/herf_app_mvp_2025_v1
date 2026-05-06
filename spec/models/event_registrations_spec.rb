# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventRegistration, type: :model do
  subject do
    build(:event_registration)
  end

  # ---- Associations ----

  describe 'associations' do
    it { is_expected.to belong_to(:event) }
  end

  # ---- Validations ----

  describe 'validations' do
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:number_of_guests) }

    it {
      is_expected.to validate_numericality_of(:number_of_guests)
        .only_integer
        .is_greater_than_or_equal_to(0)
        .is_less_than_or_equal_to(10)
    }

    it {
      is_expected.to validate_uniqueness_of(:email).scoped_to(:event_id)
                                                   .with_message('is already registered for this event')
    }

    describe 'email format' do
      it 'rejects invalid emails' do
        subject.email = 'not-an-email'
        expect(subject).not_to be_valid
        expect(subject.errors[:email]).to include('must be a valid email address')
      end

      it 'accepts valid emails' do
        subject.email = 'valid@example.com'
        subject.valid?
        expect(subject.errors[:email]).to be_empty
      end
    end

    describe '#event_must_be_upcoming' do
      it 'is invalid when the event date is in the past' do
        past_event = build(:event, date: 1.day.ago)
        registration = build(:event_registration, event: past_event)

        expect(registration).not_to be_valid
        expect(registration.errors[:event]).to include('has already occurred')
      end

      it 'is valid when the event date is today or in the future' do
        future_event = build(:event, date: 1.day.from_now)
        registration = build(:event_registration, event: future_event)

        registration.valid?
        expect(registration.errors[:event]).to be_empty
      end
    end

    describe '#capacity_not_exceeded' do
      let(:event) { create(:event, capacity: 10) }

      it 'is valid when spots are available' do
        registration = build(:event_registration, event: event, number_of_guests: 5)
        registration.valid?
        expect(registration.errors[:base]).to be_empty
      end

      it 'is invalid when guest count exceeds remaining spots' do
        # Fill up most of the capacity with existing registrations
        create(:event_registration, event: event, number_of_guests: 8)

        registration = build(:event_registration, event: event, number_of_guests: 5)
        expect(registration).not_to be_valid
        expect(registration.errors[:number_of_guests].first).to include('exceeds available spots')
      end

      it 'is invalid when event is at full capacity' do
        create(:event_registration, event: event, number_of_guests: 10)

        registration = build(:event_registration, event: event, number_of_guests: 1)
        expect(registration).not_to be_valid
        expect(registration.errors[:base]).to include('This event is at full capacity')
      end

      it 'allows registration when event has no capacity limit' do
        unlimited_event = create(:event, capacity: nil)
        registration = build(:event_registration, event: unlimited_event, number_of_guests: 10)

        registration.valid?
        expect(registration.errors[:base]).to be_empty
      end
    end
  end

  # ---- Callbacks ----

  describe 'callbacks' do
    describe '#generate_registration_token' do
      it 'auto-generates a token on create' do
        registration = build(:event_registration, registration_token: nil)
        registration.valid?
        expect(registration.registration_token).to be_present
      end

      it 'does not overwrite an existing token' do
        existing_token = SecureRandom.uuid
        registration = build(:event_registration, registration_token: existing_token)
        registration.valid?
        expect(registration.registration_token).to eq(existing_token)
      end
    end
  end

  # ---- Enums ----

  describe 'enums' do
    it { is_expected.to define_enum_for(:status).with_values(registered: 0, cancelled: 1) }
  end

  # ---- Scopes ----

  describe 'scopes' do
    describe '.active' do
      it 'returns only registered (non-cancelled) registrations' do
        active = create(:event_registration, status: :registered)
        cancelled = create(:event_registration, :cancelled)

        expect(described_class.active).to include(active)
        expect(described_class.active).not_to include(cancelled)
      end
    end
  end

  # ---- Instance Methods ----

  describe '#full_name' do
    it 'returns first and last name' do
      registration = build(:event_registration, first_name: 'John', last_name: 'Doe')
      expect(registration.full_name).to eq('John Doe')
    end
  end

  describe '#cancel!' do
    it 'sets the status to cancelled' do
      registration = create(:event_registration)
      registration.cancel!
      expect(registration.reload).to be_cancelled
    end
  end

  # ---- Class Methods ----

  describe '.find_by_token' do
    it 'finds a registration by its token' do
      registration = create(:event_registration)
      found = described_class.find_by_token(registration.registration_token)
      expect(found).to eq(registration)
    end

    it 'returns nil for an unknown token' do
      expect(described_class.find_by_token('nonexistent')).to be_nil
    end
  end

  describe '.find_by_token!' do
    it 'raises ActiveRecord::RecordNotFound for an unknown token' do
      expect do
        described_class.find_by_token!('nonexistent')
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
