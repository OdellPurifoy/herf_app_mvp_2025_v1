# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Event, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:event)).to be_valid
  end

  let(:event) { FactoryBot.build(:event) }

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

  describe 'instance methods' do
    describe '#end_time_after_start_time' do
      it 'is valid when end_time is after start_time' do
        event.end_time = event.start_time + 1.hour
        expect(event).to be_valid
      end

      it 'is invalid when end_time is before start_time' do
        event.end_time = event.start_time - 1.hour
        expect(event).not_to be_valid
      end
    end

    describe '#date_not_in_past' do
      it 'is valid when date is in the future' do
        event.date = Date.today + 1.day
        expect(event).to be_valid
      end

      it 'is invalid when date is in the past' do
        event.date = Date.today - 1.day
        expect(event).not_to be_valid
      end
    end
  end
end
