# frozen_string_literal: true

# Configure the Pay gem
Pay.setup do |config|
  # For use in email templates
  config.business_name = 'HERF App'
  config.business_address = '123 Main St, City, State ZIP'
  config.application_name = 'HERF App'
  config.support_email = 'support@example.com'

  # Stripe configuration
  config.enabled_processors = [:stripe]
  # config.adapters = [:stripe]
  config.automount_routes = true
  config.routes_path = '/pay'
  config.send_emails = true
end
