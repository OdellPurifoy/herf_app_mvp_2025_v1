# frozen_string_literal: true

class SmsNotificationService
  def initialize(to:, body:)
    @to = to
    @body = body
  end

  def send_message
    return unless valid_phone_number?
    return if Rails.env.test?

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
    rescue Twilio::REST::RestError => e
      Rails.logger.error "Twilio error: #{e.message}"
      Rails.logger.error "Using account SID: #{account_sid[0..5]}..."
      Rails.logger.error "Sending to: #{formatted_phone_number}"
      false
    end
  end

  private

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
    number = @to.gsub(/\D/, '')
    "+1#{number}" unless number.start_with?('+1')
  end
end