# frozen_string_literal: true

namespace :email do
  desc 'Send a test email to verify email configuration'
  task :test, [:email_address] => :environment do |_t, args|
    if args[:email_address].blank?
      puts '❌ ERROR: Email address is required'
      puts ''
      puts 'Usage: rails email:test[your@email.com]'
      puts 'Example: rails email:test[john@example.com]'
      exit 1
    end

    puts '📧 Testing Email Configuration...'
    puts '================================='
    puts ''
    puts 'Email Settings:'
    puts "Delivery Method: #{ActionMailer::Base.delivery_method}"
    puts "SMTP Address: #{ActionMailer::Base.smtp_settings[:address]}" if ActionMailer::Base.delivery_method == :smtp
    puts 'From Address: ApplicationMailer.default[:from]'
    puts "To Address: #{args[:email_address]}"
    puts ''
    puts 'Sending test email...'
    puts ''

    begin
      # Create a simple test mailer
      TestMailer.test_email(args[:email_address]).deliver_now

      puts '✅ SUCCESS! Email sent successfully.'
      puts ''

      if Rails.env.development?
        puts 'In development, the email should open in your browser (letter_opener).'
      else
        puts 'Check your inbox for the test email.'
        puts 'Also check your spam/junk folder if you don\'t see it.'
        puts ''
        puts 'If using SendGrid, you can check delivery status at:'
        puts 'https://app.sendgrid.com/email_activity'
      end
    rescue StandardError => e
      puts '❌ FAILED! Could not send email.'
      puts "Error: #{e.message}"
      puts ''
      puts 'Common issues:'
      puts '1. Invalid SendGrid API key'
      puts '2. Sender email not verified in SendGrid'
      puts '3. Missing SENDGRID_API_KEY environment variable'
      puts '4. Invalid recipient email address'
    end
  end

  desc 'Verify email credentials without sending'
  task verify: :environment do
    puts '🔍 Verifying Email Configuration...'
    puts '===================================='
    puts ''

    puts "Environment: #{Rails.env}"
    puts "Delivery Method: #{ActionMailer::Base.delivery_method}"
    puts ''

    if Rails.env.production? || ENV['SENDGRID_API_KEY'].present?
      puts 'SendGrid Configuration:'
      puts "API Key: #{ENV['SENDGRID_API_KEY'] ? '✓ Set' : '✗ Missing'}"
      puts "App Host: #{ENV['APP_HOST'] || '✗ Missing'}"

      if ActionMailer::Base.smtp_settings
        puts ''
        puts 'SMTP Settings:'
        puts "  Address: #{ActionMailer::Base.smtp_settings[:address]}"
        puts "  Port: #{ActionMailer::Base.smtp_settings[:port]}"
        puts "  Domain: #{ActionMailer::Base.smtp_settings[:domain]}"
        puts "  Authentication: #{ActionMailer::Base.smtp_settings[:authentication]}"
      end
    else
      puts 'Development Configuration:'
      puts 'Using letter_opener - emails will open in browser'
    end

    puts ''
    puts 'To send a test email, run:'
    puts 'rails email:test[your@email.com]'
  end
end
