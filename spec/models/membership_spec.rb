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

      context 'when membership count is below limit' do
        before do
          create_list(:membership, 49, lounge: lounge)
        end

        it 'allows creating a new membership' do
          new_membership = build(:membership, lounge: lounge)
          expect(new_membership).to be_valid
        end
      end

      context 'when membership count equals limit' do
        before do
          create_list(:membership, 50, lounge: lounge)
        end

        it 'does not allow creating a new membership' do
          new_membership = build(:membership, lounge: lounge)
          expect(new_membership).not_to be_valid
          expect(new_membership.errors[:base]).to include('Membership limit reached. Your Robusto plan allows up to 50 members. Please upgrade to add more members.')
        end
      end

      context 'when membership count exceeds limit' do
        before do
          # Create exactly at the limit using create! which bypasses our validation on seed data
          # In real world, this shouldn't happen, but we test the validation behavior
          allow_any_instance_of(Membership).to receive(:membership_limit_not_exceeded)
          create_list(:membership, 50, lounge: lounge)
          allow_any_instance_of(Membership).to receive(:membership_limit_not_exceeded).and_call_original
        end

        it 'does not allow creating a new membership' do
          new_membership = build(:membership, lounge: lounge)
          expect(new_membership).not_to be_valid
          expect(new_membership.errors[:base]).to include('Membership limit reached. Your Robusto plan allows up to 50 members. Please upgrade to add more members.')
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

      context 'when membership count is below limit' do
        before do
          create_list(:membership, 149, lounge: lounge)
        end

        it 'allows creating a new membership' do
          new_membership = build(:membership, lounge: lounge)
          expect(new_membership).to be_valid
        end
      end

      context 'when membership count equals limit' do
        before do
          create_list(:membership, 150, lounge: lounge)
        end

        it 'does not allow creating a new membership' do
          new_membership = build(:membership, lounge: lounge)
          expect(new_membership).not_to be_valid
          expect(new_membership.errors[:base]).to include('Membership limit reached. Your Churchill plan allows up to 150 members. Please upgrade to add more members.')
        end
      end
    end
  end
end
