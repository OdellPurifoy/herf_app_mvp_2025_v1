# frozen_string_literal: true

class SubscriptionPlan
  PLANS = {
    monthly: {
      name: 'Monthly',
      stripe_price_id: ENV.fetch('STRIPE_MONTHLY_PRICE_ID', 'price_monthly'),
      amount: 1900, # $19.00
      interval: 'month',
      features: [
        '1 Lounge',
        'Unlimited Members',
        'Two Events',
        'Two Special Offers'
      ]
    },
    yearly: {
      name: 'Yearly',
      stripe_price_id: ENV.fetch('STRIPE_YEARLY_PRICE_ID', 'price_yearly'),
      amount: 4900, # $49.00
      interval: 'year',
      features: [
        'Multiple Lounges',
        'Unlimited Members',
        'Unlimited Events',
        'Unlimited Special Offers',
        'Premium Support',
        'Advanced Analytics'
      ]
    }
  }.freeze

  def self.find(name)
    PLANS[name.to_sym]
  end
end
