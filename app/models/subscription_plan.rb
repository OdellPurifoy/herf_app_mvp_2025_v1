# frozen_string_literal: true

class SubscriptionPlan
  PLANS = {
    # Legacy plans - do not use for new signups
    robusto_monthly: {
      name: 'Robusto',
      stripe_price_id: ENV.fetch('STRIPE_ROBUSTO_MONTHLY_PRICE_ID', 'price_robusto_monthly'),
      amount: 4900,
      interval: 'month',
      features: [
        'Up to 50 members',
        'Up to 2 events per month',
        'Email notifications',
        '2 reminder messages per event',
        'Two Special Offers',
        'Email support'
      ]
    },
    churchill_monthly: {
      name: 'Churchill',
      stripe_price_id: ENV.fetch('STRIPE_CHURCHILL_MONTHLY_PRICE_ID', 'price_churchill_monthly'),
      amount: 9900,
      interval: 'month',
      features: [
        'Up to 150 members',
        'Unlimited events',
        'Email notifications',
        '2 reminder messages per event',
        'Unlimited Special Offers',
        'Priority email support'
      ]
    },

    # Active plans
    corona_monthly: {
      name: 'Corona',
      stripe_price_id: ENV.fetch('STRIPE_CORONA_MONTHLY_PRICE_ID', 'price_corona_monthly'),
      amount: 1900, # $19.00
      interval: 'month',
      features: [
        'Up to 300 members',
        'Up to 4 events per month',
        'Email notifications',
        '2 reminder messages per event',
        'Two Special Offers',
        'Email support'
      ]
    },
    toro_monthly: {
      name: 'Toro',
      stripe_price_id: ENV.fetch('STRIPE_TORO_MONTHLY_PRICE_ID', 'price_toro_monthly'),
      amount: 3900, # $39.00
      interval: 'month',
      features: [
        'Unlimited members',
        'Unlimited events',
        'Email notifications',
        '2 reminder messages per event',
        'Unlimited Special Offers',
        'Priority email support'
      ]
    }
  }.freeze

  def self.find(name)
    PLANS[name.to_sym]
  end
end
