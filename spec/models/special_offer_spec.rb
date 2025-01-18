# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SpecialOffer, type: :model do
  let(:lounge) { FactoryBot.create(:lounge) }
  let(:special_offer) { FactoryBot.create(:special_offer, lounge: lounge) }

  it 'has a valid factory' do
    expect(special_offer).to be_valid
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:offer_type) }
    it { is_expected.to validate_presence_of(:start_date) }
    it { is_expected.to validate_presence_of(:end_date) }

    it 'is invalid if the end date is before the start date' do
      special_offer.end_date = special_offer.start_date - 1.day
      expect(special_offer).to be_invalid
      expect(special_offer.errors[:end_date]).to include('must be after the start date')
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:lounge) }
  end
end
