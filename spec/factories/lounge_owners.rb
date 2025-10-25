# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :lounge_owner do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    phone_number { Faker::PhoneNumber.phone_number }
    date_of_birth { 25.years.ago.to_date }

    trait :with_stripe_customer do
      after(:create) do |lounge_owner|
        # Create the payment processor correctly
        lounge_owner.payment_processor.update!(processor_id: 'cus_test123')
      end
    end

    trait :with_subscription do
      with_stripe_customer

      after(:create) do |lounge_owner|
        customer = lounge_owner.payment_processor
        customer.subscriptions.create!(
          name: 'robusto_monthly',
          processor_id: 'sub_test123',
          processor_plan: 'price_robusto_test',
          status: 'active',
          current_period_start: Time.current,
          current_period_end: 1.month.from_now
        )
      end
    end
  end
end
