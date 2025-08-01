module StripeHelpers
  def stub_stripe_customer_create
    customer = Stripe::Customer.construct_from(
      id: 'cus_test123',
      email: 'test@example.com',
      object: 'customer'
    )

    allow(Stripe::Customer).to receive(:create).and_return(customer)
    customer
  end

  def stub_stripe_subscription_create(customer_id: 'cus_test123', price_id: 'price_test123')
    subscription = Stripe::Subscription.construct_from(
      id: 'sub_test123',
      customer: customer_id,
      status: 'active',
      items: {
        data: [{
          price: { id: price_id }
        }]
      },
      current_period_start: Time.current.to_i,
      current_period_end: 1.month.from_now.to_i
    )

    allow(Stripe::Subscription).to receive(:create).and_return(subscription)
    subscription
  end

  def stub_stripe_checkout_session_create
    session = Stripe::Checkout::Session.construct_from(
      id: 'cs_test123',
      url: 'https://checkout.stripe.com/pay/cs_test123',
      customer: 'cus_test123',
      subscription: 'sub_test123'
    )

    allow(Stripe::Checkout::Session).to receive(:create).and_return(session)
    session
  end

  def stub_stripe_billing_portal_session_create
    session = Stripe::BillingPortal::Session.construct_from(
      id: 'bps_test123',
      url: 'https://billing.stripe.com/session/bps_test123'
    )

    allow(Stripe::BillingPortal::Session).to receive(:create).and_return(session)
    session
  end

  def create_stripe_webhook_event(type:, data: {})
    {
      id: "evt_test_#{SecureRandom.hex(8)}",
      object: 'event',
      api_version: '2022-11-15',
      created: Time.current.to_i,
      data: {
        object: data
      },
      livemode: false,
      pending_webhooks: 1,
      request: {
        id: "req_test_#{SecureRandom.hex(8)}",
        idempotency_key: nil
      },
      type: type
    }
  end
end
