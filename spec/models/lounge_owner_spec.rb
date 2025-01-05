require 'rails_helper'

RSpec.describe LoungeOwner, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:lounge_owner)).to be_valid
  end

  let(:lounge_owner) { FactoryBot.build(:lounge_owner) }

  # describe 'ActiveRecord associations' do
  #   it { expect(lounge_owner).to have_many(:lounges).dependent(:destroy) }
  # end

  describe 'ActiveModel validations' do
    it { expect(lounge_owner).to validate_presence_of(:first_name) }
    it { expect(lounge_owner).to validate_presence_of(:last_name) }
    it { expect(lounge_owner).to validate_presence_of(:date_of_birth) }
    it { expect(lounge_owner).to validate_presence_of(:email) }
    it { expect(lounge_owner).to validate_presence_of(:password) }
  end

  describe 'validations' do
    it 'validates date_of_birth is not in the future' do
      lounge_owner.date_of_birth = Date.today + 1.day

      expect(lounge_owner).to be_invalid
      expect(lounge_owner.errors[:date_of_birth]).to include("can't be in the future")
    end

    it 'validates date_of_birth is 18 years or older' do
      lounge_owner.date_of_birth = 17.years.ago

      expect(lounge_owner).to be_invalid
      expect(lounge_owner.errors[:date_of_birth]).to include('must be 18 years or older')
    end
  end
end
