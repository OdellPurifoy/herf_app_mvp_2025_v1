# frozen_string_literal: true

module ApplicationHelper
  def format_phone_number(phone_number)
    phone_number.gsub(/\D/, '').sub(/^1/, '').gsub(/(\d{3})(\d{3})(\d{4})/, '(\1) \2-\3')
  end
end
