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
end
