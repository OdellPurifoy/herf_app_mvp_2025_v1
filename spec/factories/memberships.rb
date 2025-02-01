# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :membership do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    phone_number { Faker::PhoneNumber.phone_number }
    opt_out_text_messaging { false }
    allow_text_notifications { false }
    allow_email_notifications { false }
    lounge
  end
end
