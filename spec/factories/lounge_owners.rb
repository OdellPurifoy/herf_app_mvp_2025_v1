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
        # Mock the payment processor instead of actually creating it
        payment_processor = double('payment_processor', processor_id: 'cus_test123')
        allow(lounge_owner).to receive(:payment_processor).and_return(payment_processor)
      end
    end

    trait :with_subscription do
      after(:create) do |lounge_owner|
        # Mock that the user has an active subscription
        allow(lounge_owner).to receive(:subscribed?).and_return(true)

        # Mock the payment processor
        payment_processor = double('payment_processor', processor_id: 'cus_test123')
        allow(lounge_owner).to receive(:payment_processor).and_return(payment_processor)
      end
    end
  end
end
