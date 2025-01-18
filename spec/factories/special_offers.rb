# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :special_offer do
    name { 'Special Offer' }
    offer_type { SpecialOffer::TYPES.sample }
    start_date { Faker::Date.between(from: '2021-01-18', to: '2025-01-18') }
    end_date { start_date + 1.week }
    members_only { false }
    offer_code { 'BOGO123' }
    description { Faker::Lorem.paragraph }
    lounge
  end
end
