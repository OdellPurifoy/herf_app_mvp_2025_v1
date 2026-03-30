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

  describe 'subscription plan validations' do
    context 'with Corona subscription' do
      let(:lounge_owner) { create(:lounge_owner, :with_stripe_customer) }
      let(:lounge) { create(:lounge, lounge_owner: lounge_owner) }

      before do
        customer = lounge_owner.payment_processor
        customer.subscriptions.create!(
          name: 'corona_monthly',
          processor_id: 'sub_corona',
          processor_plan: 'price_corona_monthly',
          status: 'active',
          current_period_start: Time.current,
          current_period_end: 1.month.from_now
        )
      end

      context 'when special offer count is below monthly limit' do
        before do
          create(:special_offer, lounge: lounge, start_date: 2.weeks.from_now.to_date,
                                 end_date: 3.weeks.from_now.to_date)
        end

        it 'allows creating a new special offer in the same month' do
          new_offer = build(:special_offer, lounge: lounge, start_date: 3.weeks.from_now.to_date,
                                            end_date: 4.weeks.from_now.to_date)
          expect(new_offer).to be_valid
        end
      end

      context 'when special offer count equals monthly limit' do
        before do
          next_month = 1.month.from_now.beginning_of_month
          create(:special_offer, lounge: lounge, start_date: next_month + 9.days,
                                 end_date: next_month + 16.days)
          create(:special_offer, lounge: lounge, start_date: next_month + 17.days,
                                 end_date: next_month + 24.days)
        end

        it 'does not allow creating a new special offer in the same month' do
          next_month = 1.month.from_now.beginning_of_month
          new_offer = build(:special_offer, lounge: lounge, start_date: next_month + 25.days,
                                            end_date: next_month + 29.days)
          expect(new_offer).not_to be_valid
          expect(new_offer.errors[:base]).to include('Special offer limit reached. Your Corona_monthly plan allows up to 2 special offers per month. Please upgrade to create more offers.')
        end
      end

      context 'when special offer count equals limit but in different months' do
        before do
          create(:special_offer, lounge: lounge, start_date: 2.weeks.from_now.to_date,
                                 end_date: 3.weeks.from_now.to_date)
          create(:special_offer, lounge: lounge, start_date: 3.weeks.from_now.to_date,
                                 end_date: 4.weeks.from_now.to_date)
        end

        it 'allows creating a new special offer in a different month' do
          new_offer = build(:special_offer, lounge: lounge, start_date: 2.months.from_now.to_date,
                                            end_date: 2.months.from_now.to_date + 1.week)
          expect(new_offer).to be_valid
        end
      end

      context 'when special offer count exceeds monthly limit' do
        before do
          # Create exactly at the limit (2 for Corona)
          next_month = 1.month.from_now.beginning_of_month
          create(:special_offer, lounge: lounge, start_date: next_month + 9.days,
                                 end_date: next_month + 16.days)
          create(:special_offer, lounge: lounge, start_date: next_month + 17.days,
                                 end_date: next_month + 24.days)
        end

        it 'does not allow creating a new special offer in the same month' do
          next_month = 1.month.from_now.beginning_of_month
          new_offer = build(:special_offer, lounge: lounge, start_date: next_month + 25.days,
                                            end_date: next_month + 29.days)
          expect(new_offer).not_to be_valid
          expect(new_offer.errors[:base]).to include('Special offer limit reached. Your Corona_monthly plan allows up to 2 special offers per month. Please upgrade to create more offers.')
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

      context 'when creating many special offers in the same month' do
        before do
          create_list(:special_offer, 10, lounge: lounge, start_date: 2.weeks.from_now.to_date,
                                          end_date: 3.weeks.from_now.to_date)
        end

        it 'allows creating unlimited special offers' do
          new_offer = build(:special_offer, lounge: lounge, start_date: 3.weeks.from_now.to_date,
                                            end_date: 4.weeks.from_now.to_date)
          expect(new_offer).to be_valid
        end
      end
    end
  end
end
