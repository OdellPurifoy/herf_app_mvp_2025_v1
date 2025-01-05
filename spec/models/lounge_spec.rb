require 'rails_helper'

RSpec.describe Lounge, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:lounge)).to be_valid
  end

  let(:lounge) { FactoryBot.build(:lounge) }

  describe 'ActiveRecord associations' do
    it { expect(lounge).to belong_to(:lounge_owner) }
  end

  describe 'ActiveRecord validations' do
    it { expect(lounge).to validate_presence_of(:name) }
    it { expect(lounge).to validate_presence_of(:address_street_1) }
    it { expect(lounge).to validate_presence_of(:city) }
    it { expect(lounge).to validate_presence_of(:state) }
    it { expect(lounge).to validate_presence_of(:zip_code) }
    it { expect(lounge).to validate_presence_of(:email) }
  end
end
