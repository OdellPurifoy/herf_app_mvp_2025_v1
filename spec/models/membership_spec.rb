# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Membership, type: :model do
  let(:lounge) { FactoryBot.create(:lounge) }
  let(:membership) { FactoryBot.create(:membership, lounge: lounge) }

  it 'has a valid factory' do
    expect(membership).to be_valid
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:lounge) }
  end
end
