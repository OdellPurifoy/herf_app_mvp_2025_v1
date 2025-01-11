# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :lounge do
    name { Faker::Company.name }
    address_street_1 { Faker::Address.street_address }
    address_street_2 { Faker::Address.secondary_address }
    city { Faker::Address.city }
    state { Faker::Address.state }
    zip_code { Faker::Address.zip_code }
    phone_number { Faker::PhoneNumber.phone_number }
    email { Faker::Internet.email }
    facebook_handle { 'https://facebook.com/fake_lounge' }
    x_handle { 'https://x.com/fake_lounge' }
    instagram_handle { 'https://instagram.com/fake_lounge' }
    outside_cigars_allowed { false }
    outside_food_allowed { false }
    alcohol_served { false }
    outside_alcohol_allowed { false }
    food_served { false }
    website { 'https://fakelounge.com' }
    lounge_owner
  end
end
