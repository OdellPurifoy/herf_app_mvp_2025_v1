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

  describe 'scopes' do
    describe '.active' do
      it 'returns only active memberships' do
        active_membership = FactoryBot.create(:membership, lounge: lounge, active: true)
        inactive_membership = FactoryBot.create(:membership, lounge: lounge, active: false)

        expect(Membership.active).to include(active_membership)
        expect(Membership.active).not_to include(inactive_membership)
      end
    end

    describe '.inactive' do
      it 'returns only inactive memberships' do
        active_membership = FactoryBot.create(:membership, lounge: lounge, active: true)
        inactive_membership = FactoryBot.create(:membership, lounge: lounge, active: false)

        expect(Membership.inactive).to include(inactive_membership)
        expect(Membership.inactive).not_to include(active_membership)
      end
    end
  end
end
