#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'twilio-ruby'
require 'dotenv/load'

puts 'Testing Twilio API Connection...'
puts '================================='
puts ''

account_sid = ENV['TWILIO_ACCOUNT_SID']
auth_token = ENV['TWILIO_AUTH_TOKEN']
from_number = ENV['TWILIO_PHONE_NUMBER']

puts "Account SID: #{account_sid}"
puts "Auth Token Length: #{auth_token&.length} characters"
puts "From Number: #{from_number}"
puts ''

begin
  client = Twilio::REST::Client.new(account_sid, auth_token)

  # Try to fetch account info to verify credentials
  puts 'Attempting to authenticate with Twilio...'
  account = client.api.accounts(account_sid).fetch

  puts '✅ Authentication successful!'
  puts "Account Status: #{account.status}"
  puts "Account Type: #{account.type}"
  puts ''

  # Now try to send a test message
  print 'Enter phone number to send test SMS (e.g., 9178687000): '
  to_number = gets.chomp

  if to_number.present?
    puts ''
    puts "Sending test SMS to #{to_number}..."

    message = client.messages.create(
      from: from_number,
      to: to_number.start_with?('+') ? to_number : "+1#{to_number.gsub(/\D/, '')}",
      body: '🎉 Test message from HERF App! Your Twilio integration is working correctly.'
    )

    puts '✅ SMS sent successfully!'
    puts "Message SID: #{message.sid}"
    puts "Status: #{message.status}"
  end
rescue Twilio::REST::RestError => e
  puts '❌ Twilio API Error:'
  puts "Error Code: #{e.code}"
  puts "Error Message: #{e.message}"
  puts ''
  puts 'Please verify your credentials in the Twilio Console:'
  puts 'https://console.twilio.com/'
rescue StandardError => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(5)
end
