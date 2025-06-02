# frozen_string_literal: true

class SmsNotificationService
  @@test_mode = false
  @@test_messages = []

  class << self
    def enable_test_mode!
      @@test_mode = true
      @@test_messages = []
    end

    def disable_test_mode!
      @@test_mode = false
    end

    def test_messages
      @@test_messages
    end

    def clear_test_messages!
      @@test_messages = []
    end
  end

  def initialize(to:, body:)
    @to = to
    @body = body
  end

  def send_message
    return unless valid_phone_number?

    if @@test_mode || Rails.env.test?
      store_test_message
      return true
    end

    begin
      Rails.logger.info "Attempting to send SMS to #{formatted_phone_number}"
      client = Twilio::REST::Client.new(account_sid, auth_token)

      message = client.messages.create(
        from: twilio_phone_number,
        to: formatted_phone_number,
        body: @body
      )
      Rails.logger.info "SMS sent successfully, SID: #{message.sid}"
      true
    rescue Twilio::REST::RestError, StandardError => e
      Rails.logger.error "Twilio error: #{e.message}"
      Rails.logger.error "Using account SID: #{account_sid[0..5]}..."
      Rails.logger.error "Sending to: #{formatted_phone_number}"
      false
    end
  end

  private

  def store_test_message
    test_message = {
      to: formatted_phone_number,
      body: @body,
      timestamp: Time.current
    }

    @@test_messages << test_message

    # Log the test message for convenience
    Rails.logger.info "[TEST MODE] SMS would be sent to #{formatted_phone_number}"
    Rails.logger.info "[TEST MODE] Message: #{@body}"

    true
  end

  def account_sid
    ENV['TWILIO_ACCOUNT_SID']
  end

  def auth_token
    ENV['TWILIO_AUTH_TOKEN']
  end

  def twilio_phone_number
    ENV['TWILIO_PHONE_NUMBER']
  end

  def valid_phone_number?
    @to.present? && @to.gsub(/\D/, '').length >= 10
  end

  def formatted_phone_number
    if @to.start_with?('+1')
      @to # Return the number as is if it already starts with +1
    else
      number = @to.gsub(/\D/, '')
      "+1#{number}"
    end
  end
end
