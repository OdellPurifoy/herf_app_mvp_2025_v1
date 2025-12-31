# frozen_string_literal: true

namespace :twilio do
  desc 'Send a test SMS to verify Twilio configuration'
  task :test, [:phone_number] => :environment do |_t, args|
    if args[:phone_number].blank?
      puts '❌ ERROR: Phone number is required'
      puts ''
      puts 'Usage: rails twilio:test[YOUR_PHONE_NUMBER]'
      puts 'Example: rails twilio:test[5551234567]'
      puts 'Example: rails twilio:test[+15551234567]'
      exit 1
    end

    puts '🔧 Testing Twilio Configuration...'
    puts '================================='
    puts ''
    puts 'Twilio Credentials:'
    puts "Account SID: #{ENV['TWILIO_ACCOUNT_SID'][0..5]}..."
    puts "Auth Token: #{ENV['TWILIO_AUTH_TOKEN'] ? '✓ Set' : '✗ Missing'}"
    puts "Phone Number: #{ENV['TWILIO_PHONE_NUMBER']}"
    puts ''
    puts "Sending test SMS to: #{args[:phone_number]}"
    puts ''

    service = SmsNotificationService.new(
      to: args[:phone_number],
      body: '🎉 Test message from HERF App! Your Twilio integration is working correctly.'
    )

    result = service.send_message

    puts ''
    if result
      puts '✅ SUCCESS! SMS sent successfully.'
      puts 'Check your phone for the test message.'
      puts ''
      puts 'If you don\'t receive the message within a few minutes, check:'
      puts '1. Your Twilio account has sufficient credits'
      puts '2. The phone number is verified in your Twilio account (if using trial)'
      puts '3. The phone number format is correct'
    else
      puts '❌ FAILED! Could not send SMS.'
      puts 'Check the error messages above for details.'
      puts ''
      puts 'Common issues:'
      puts '1. Invalid Twilio credentials'
      puts '2. Trial account with unverified phone number'
      puts '3. Insufficient Twilio credits'
      puts '4. Invalid phone number format'
    end
  end

  desc 'Verify Twilio credentials without sending a message'
  task verify: :environment do
    puts '🔍 Verifying Twilio Configuration...'
    puts '===================================='
    puts ''

    account_sid = ENV['TWILIO_ACCOUNT_SID']
    auth_token = ENV['TWILIO_AUTH_TOKEN']
    phone_number = ENV['TWILIO_PHONE_NUMBER']

    puts "Account SID: #{account_sid ? "#{account_sid[0..5]}... ✓" : '✗ Missing'}"
    puts "Auth Token: #{auth_token ? '✓ Set' : '✗ Missing'}"
    puts "Phone Number: #{phone_number || '✗ Missing'}"
    puts ''

    if account_sid.present? && auth_token.present? && phone_number.present?
      puts '✅ All Twilio credentials are configured.'
      puts ''
      puts 'To send a test SMS, run:'
      puts 'rails twilio:test[YOUR_PHONE_NUMBER]'
    else
      puts '❌ Missing Twilio credentials in .env file'
      puts ''
      puts 'Required environment variables:'
      puts 'TWILIO_ACCOUNT_SID'
      puts 'TWILIO_AUTH_TOKEN'
      puts 'TWILIO_PHONE_NUMBER'
    end
  end
end
