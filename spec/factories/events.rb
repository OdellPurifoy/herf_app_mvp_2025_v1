# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :event do
    name { Faker::Lorem.word }
    event_type { Event::TYPES.sample }
    date { Date.today + 1.week }
    start_time { Faker::Time.between(from: DateTime.now, to: (DateTime.now + 1.hour)) }
    end_time { Faker::Time.between(from: (DateTime.now + 3.hours), to: (DateTime.now + 4.hours)) }
    virtual { false }
    members_only { false }
    description { Faker::Lorem.paragraph }
    rsvp_needed { false }
    capacity { 1 }
    entry_fee { Faker::Number.decimal(l_digits: 2) }
    lounge
  end
end
