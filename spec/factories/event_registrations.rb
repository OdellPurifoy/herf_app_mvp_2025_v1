# frozen_string_literal: true

FactoryBot.define do
  factory :event_registration do
    event
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    phone_number { Faker::PhoneNumber.cell_phone }
    number_of_guests { 1 }
    status { :registered }
    opt_in_to_membership { false }
    registration_token { SecureRandom.uuid }

    trait :with_guests do
      number_of_guests { 4 }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :opted_in do
      opt_in_to_membership { true }
    end
  end
end
