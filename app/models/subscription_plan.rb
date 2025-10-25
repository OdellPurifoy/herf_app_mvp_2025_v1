# frozen_string_literal: true

class SubscriptionPlan
  PLANS = {
    robusto_monthly: {
      name: 'Robusto',
      stripe_price_id: ENV.fetch('STRIPE_ROBUSTO_MONTHLY_PRICE_ID', 'price_robusto_monthly'),
      amount: 4900, # $49.00
      interval: 'month',
      features: [
        'Up to 50 members',
        'Up to 2 events per month',
        'SMS & Email notifications',
        '2 reminder messages per event',
        'Basic Analytics',
        'Email support',
        'Two Special Offers'
      ]
    },
    churchill_monthly: {
      name: 'Churchill',
      stripe_price_id: ENV.fetch('STRIPE_CHURCHILL_MONTHLY_PRICE_ID', 'price_churchill_monthly'),
      amount: 9900, # $99.00
      interval: 'month',
      features: [
        'Up to 150 members',
        'Unlimited Events',
        'SMS & Email Support',
        '2 reminder messages per event',
        'Advanced Analytics',
        'Priority Email Support',
        'Unlimited Special Offers'
      ]
    }
  }.freeze

  def self.find(name)
    PLANS[name.to_sym]
  end
end
