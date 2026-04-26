# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :event do
    name { Faker::Lorem.word }
    event_type { Event::TYPES.sample }

    # Use concrete values instead of lambdas
    date { Date.today + 1.week }
    start_time { Time.zone.today + 2.hours }

    # Set end time explicitly in relation to start time
    end_time { Time.zone.today + 3.hours }

    virtual { false }
    virtual_url { nil }
    virtual_passcode { Faker::Alphanumeric.alphanumeric(number: 10) }
    description { Faker::Lorem.paragraph }
    rsvp_needed { false }
    capacity { 1 }
    entry_fee { Faker::Number.decimal(l_digits: 2) }
    association :lounge
  end
end
