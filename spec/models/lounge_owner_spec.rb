# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LoungeOwner, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:lounge_owner)).to be_valid
  end

  describe 'Pay integration' do
    let(:lounge_owner) { create(:lounge_owner) }

    it 'includes Pay customer functionality' do
      expect(lounge_owner).to respond_to(:payment_processor)
      expect(lounge_owner).to respond_to(:subscriptions)
      expect(lounge_owner).to respond_to(:charges)
    end

    describe '#subscribed?' do
      context 'with no subscriptions' do
        it 'returns false' do
          expect(lounge_owner.subscribed?).to be false
        end
      end

      context 'with active subscription' do
        let(:subscribed_owner) { create(:lounge_owner, :with_subscription) }

        it 'returns true' do
          expect(subscribed_owner.subscribed?).to be true
        end
      end

      context 'with canceled subscription' do
        let(:owner_with_canceled_sub) { create(:lounge_owner, :with_stripe_customer) }

        before do
          customer = owner_with_canceled_sub.payment_processor(:stripe)
          customer.subscriptions.create!(
            name: 'default',
            processor_id: 'sub_canceled',
            processor_plan: 'price_monthly',
            status: 'canceled',
            current_period_start: 1.month.ago,
            current_period_end: Time.current
          )
        end

        it 'returns false' do
          expect(owner_with_canceled_sub.subscribed?).to be false
        end
      end
    end

    describe '#can_create_lounge?' do
      context 'without subscription' do
        it 'returns false' do
          expect(lounge_owner.can_create_lounge?).to be false
        end
      end

      context 'with active subscription' do
        let(:subscribed_owner) { create(:lounge_owner, :with_subscription) }

        it 'returns true' do
          expect(subscribed_owner.can_create_lounge?).to be true
        end
      end
    end

    describe '#subscription_name' do
      context 'without subscription' do
        it 'returns nil' do
          expect(lounge_owner.subscription_name).to be_nil
        end
      end

      context 'with subscription' do
        let(:subscribed_owner) { create(:lounge_owner, :with_stripe_customer) }

        before do
          customer = subscribed_owner.payment_processor(:stripe)
          customer.subscriptions.create!(
            name: 'monthly',
            processor_id: 'sub_monthly',
            processor_plan: 'price_monthly',
            status: 'active',
            current_period_start: Time.current,
            current_period_end: 1.month.from_now
          )
        end

        it 'returns capitalized subscription name' do
          expect(subscribed_owner.subscription_name).to eq('Monthly')
        end
      end
    end
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
