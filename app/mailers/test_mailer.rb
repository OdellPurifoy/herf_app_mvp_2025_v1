# frozen_string_literal: true

class TestMailer < ApplicationMailer
  def test_email(to_address)
    @timestamp = Time.current
    @environment = Rails.env

    mail(
      to: to_address,
      subject: '🎉 Test Email from HERF App'
    )
  end
end
