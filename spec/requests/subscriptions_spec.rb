# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Subscriptions', type: :request do # rubocop:disable Metrics/BlockLength
  include StripeHelpers

  let(:lounge_owner) { create(:lounge_owner) }

  before do # rubocop:disable Metrics/BlockLength
    sign_in lounge_owner

    # Stub environment variables
    stub_const('ENV', ENV.to_hash.merge({
                                          'STRIPE_PUBLIC_KEY' => 'pk_test_123',
                                          'STRIPE_PRIVATE_KEY' => 'sk_test_123',
                                          'STRIPE_SIGNING_SECRET' => 'whsec_test_123',
                                          'STRIPE_MONTHLY_PRICE_ID' => 'price_monthly_test',
                                          'STRIPE_YEARLY_PRICE_ID' => 'price_yearly_test'
                                        }))

    # Mock SubscriptionPlan.find with all required fields for the view
    allow(SubscriptionPlan).to receive(:find).with('monthly').and_return({
                                                                           name: 'Monthly',
                                                                           stripe_price_id: 'price_monthly_test',
                                                                           amount: 1900, # Amount in cents
                                                                           interval: 'month',
                                                                           features: [
                                                                             'Create unlimited lounges',
                                                                             'Manage events and offers',
                                                                             'Member management',
                                                                             'Analytics dashboard'
                                                                           ]
                                                                         })

    allow(SubscriptionPlan).to receive(:find).with('yearly').and_return({
                                                                          name: 'Yearly',
                                                                          stripe_price_id: 'price_yearly_test',
                                                                          amount: 19_000, # Amount in cents
                                                                          interval: 'year',
                                                                          features: [
                                                                            'Create unlimited lounges',
                                                                            'Manage events and offers',
                                                                            'Member management',
                                                                            'Analytics dashboard',
                                                                            '2 months free'
                                                                          ]
                                                                        })

    # Handle nil case
    allow(SubscriptionPlan).to receive(:find).with(nil).and_return(nil)
  end

  describe 'GET /subscription/new' do
    context 'with monthly plan' do
      it 'displays the subscription form' do
        get new_subscription_path(plan: 'monthly')

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Monthly')
      end
    end

    context 'with yearly plan' do
      it 'displays the subscription form' do
        get new_subscription_path(plan: 'yearly')

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Yearly')
      end
    end

    context 'without plan parameter' do
      it 'redirects to pricing section' do
        get new_subscription_path

        expect(response).to redirect_to(root_path(anchor: 'pricing'))
      end
    end
  end

  describe 'POST /subscription' do
    context 'with monthly plan' do
      it 'creates a Stripe checkout session and redirects' do
        # Mock the checkout session
        checkout_session = double('checkout_session', url: 'https://checkout.stripe.com/pay/cs_test123')

        # Mock the payment processor
        payment_processor = double('payment_processor')
        allow(lounge_owner).to receive(:payment_processor).and_return(payment_processor)
        allow(payment_processor).to receive(:checkout).and_return(checkout_session)

        post subscription_path, params: { plan: 'monthly' }

        expect(response).to redirect_to(checkout_session.url)
      end
    end

    context 'with yearly plan' do
      it 'creates a Stripe checkout session with yearly pricing' do
        # Mock the checkout session
        checkout_session = double('checkout_session', url: 'https://checkout.stripe.com/pay/cs_test123')

        # Mock the payment processor
        payment_processor = double('payment_processor')
        allow(lounge_owner).to receive(:payment_processor).and_return(payment_processor)
        allow(payment_processor).to receive(:checkout).and_return(checkout_session)

        post subscription_path, params: { plan: 'yearly' }

        expect(response).to redirect_to(checkout_session.url)
      end
    end

    context 'when Stripe raises an error' do
      it 'handles the error gracefully' do
        # Mock the payment processor to raise an error
        payment_processor = double('payment_processor')
        allow(lounge_owner).to receive(:payment_processor).and_return(payment_processor)
        allow(payment_processor).to receive(:checkout).and_raise(
          Stripe::CardError.new('Your card was declined.', 'card_declined')
        )

        post subscription_path, params: { plan: 'monthly' }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('subscription')
      end
    end
  end

  describe 'GET /subscription/success' do
    it 'shows success message and redirects to dashboard' do
      get success_subscription_path

      expect(response).to redirect_to(dashboard_path)
      expect(flash[:notice]).to include('subscription is active')
    end
  end

  describe 'GET /subscription/cancel' do
    it 'shows cancellation message and redirects to root' do
      get cancel_subscription_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include('not completed')
    end
  end

  describe 'GET /subscription/billing_portal' do
    context 'when user has active subscription' do
      let(:subscribed_owner) { create(:lounge_owner) }

      before do
        sign_in subscribed_owner

        # Mock that the user has a subscription
        allow(subscribed_owner).to receive(:subscribed?).and_return(true)

        # Mock the payment processor
        payment_processor = double('payment_processor', processor_id: 'cus_test123')
        allow(subscribed_owner).to receive(:payment_processor).and_return(payment_processor)

        # Mock the billing portal session
        portal_session = double('portal_session', url: 'https://billing.stripe.com/session/bps_test123')
        allow(Stripe::BillingPortal::Session).to receive(:create).and_return(portal_session)
      end

      it 'creates billing portal session and redirects' do
        get billing_portal_subscription_path

        expect(response).to redirect_to('https://billing.stripe.com/session/bps_test123')
      end
    end

    context 'when user has no subscription' do
      before do
        sign_in lounge_owner
        allow(lounge_owner).to receive(:subscribed?).and_return(false)
      end

      it 'redirects to pricing with error' do
        get billing_portal_subscription_path

        expect(response).to redirect_to(root_path(anchor: 'pricing'))
        expect(flash[:alert]).to include('active subscription')
      end
    end
  end
end
