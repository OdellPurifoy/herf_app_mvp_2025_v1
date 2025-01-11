# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :event do
    name { Faker::Lorem.word }
    event_type { Event::TYPES.sample }
    date { Faker::Date.in_date_period }
    start_time { Faker::Time.between(from: DateTime.now - 1, to: DateTime.now) }
    end_time { Faker::Time.between(from: DateTime.now, to: DateTime.now + 1) }
    virtual { false }
    members_only { false }
    description { Faker::Lorem.paragraph }
    rsvp_needed { false }
    capacity { 1 }
    entry_fee { Faker::Number.decimal(l_digits: 2) }
    lounge
  end
end
