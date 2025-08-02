# frozen_string_literal: true

FactoryBot.define do
  factory :rsvp do
    event { nil }
    membership { nil }
    status { 'MyString' }
    guest_count { 1 }
    token { 'MyString' }
    attended { false }
  end
end
