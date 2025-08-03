# frozen_string_literal: true

require 'faker'
require 'securerandom'

FactoryBot.define do
  factory :rsvp do
    association :event
    association :membership
    status { :pending }
    guest_count { 1 }
    rsvp_token { SecureRandom.urlsafe_base64(32) }
    expires_at { 2.weeks.from_now }

    trait :attending do
      status { :attending }
      guest_count { 2 }
    end

    trait :declined do
      status { :declined }
    end

    trait :expired do
      status { :expired }
      expires_at { 1.day.ago }
    end
  end
end
