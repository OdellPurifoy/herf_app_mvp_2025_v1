# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :lounge_owner do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    date_of_birth { Faker::Date.birthday(min_age: 18, max_age: 65) }
    phone_number { '111-222-3333' }
    email { Faker::Internet.email }
    password { Faker::Internet.password }
  end

  trait :with_lounge do
    after(:create) do |lounge_owner|
      create(:lounge, lounge_owner: lounge_owner)
    end
  end
end
