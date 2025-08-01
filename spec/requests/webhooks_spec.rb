require 'rails_helper'

RSpec.describe 'Webhooks', type: :request do
  include StripeHelpers

  let(:lounge_owner) { create(:lounge_owner, :with_stripe_customer) }
  let(:stripe_customer) { lounge_owner.payment_processor(:stripe) }

  before do
    allow(Stripe::Webhook).to receive(:construct_event).and_return(webhook_event)
  end

  describe 'POST /webhooks/stripe' do
    let(:headers) do
      {
        'HTTP_STRIPE_SIGNATURE' => 'test_signature',
        'CONTENT_TYPE' => 'application/json'
      }
    end

    context 'customer.subscription.created' do
      let(:subscription_data) do
        {
          id: 'sub_test123',
          customer: stripe_customer.processor_id,
          status: 'active',
          items: {
            data: [{
              price: { id: 'price_monthly_test' }
            }]
          },
          current_period_start: Time.current.to_i,
          current_period_end: 1.month.from_now.to_i,
          metadata: {
            plan: 'monthly'
          }
        }
      end

      let(:webhook_event) do
        create_stripe_webhook_event(
          type: 'customer.subscription.created',
          data: subscription_data
        )
      end

      it 'creates a new subscription record' do
        expect do
          post '/webhooks/stripe',
               params: webhook_event.to_json,
               headers: headers
        end.to change { stripe_customer.subscriptions.count }.by(1)

        expect(response).to have_http_status(:ok)

        subscription = stripe_customer.subscriptions.last
        expect(subscription.processor_id).to eq('sub_test123')
        expect(subscription.status).to eq('active')
        expect(subscription.name).to eq('monthly')
      end
    end

    context 'customer.subscription.updated' do
      let!(:subscription) do
        stripe_customer.subscriptions.create!(
          name: 'monthly',
          processor_id: 'sub_test123',
          processor_plan: 'price_monthly_test',
          status: 'active',
          current_period_start: Time.current,
          current_period_end: 1.month.from_now
        )
      end

      let(:subscription_data) do
        {
          id: 'sub_test123',
          customer: stripe_customer.processor_id,
          status: 'past_due',
          items: {
            data: [{
              price: { id: 'price_monthly_test' }
            }]
          },
          current_period_start: Time.current.to_i,
          current_period_end: 1.month.from_now.to_i
        }
      end

      let(:webhook_event) do
        create_stripe_webhook_event(
          type: 'customer.subscription.updated',
          data: subscription_data
        )
      end

      it 'updates the subscription status' do
        post '/webhooks/stripe',
             params: webhook_event.to_json,
             headers: headers

        expect(response).to have_http_status(:ok)
        expect(subscription.reload.status).to eq('past_due')
      end
    end

    context 'customer.subscription.deleted' do
      let!(:subscription) do
        stripe_customer.subscriptions.create!(
          name: 'monthly',
          processor_id: 'sub_test123',
          processor_plan: 'price_monthly_test',
          status: 'active',
          current_period_start: Time.current,
          current_period_end: 1.month.from_now
        )
      end

      let(:subscription_data) do
        {
          id: 'sub_test123',
          customer: stripe_customer.processor_id,
          status: 'canceled'
        }
      end

      let(:webhook_event) do
        create_stripe_webhook_event(
          type: 'customer.subscription.deleted',
          data: subscription_data
        )
      end

      it 'marks the subscription as canceled' do
        post '/webhooks/stripe',
             params: webhook_event.to_json,
             headers: headers

        expect(response).to have_http_status(:ok)
        expect(subscription.reload.status).to eq('canceled')
      end
    end

    context 'invoice.payment_succeeded' do
      let!(:subscription) do
        stripe_customer.subscriptions.create!(
          name: 'monthly',
          processor_id: 'sub_test123',
          processor_plan: 'price_monthly_test',
          status: 'active',
          current_period_start: Time.current,
          current_period_end: 1.month.from_now
        )
      end

      let(:invoice_data) do
        {
          id: 'in_test123',
          customer: stripe_customer.processor_id,
          subscription: 'sub_test123',
          amount_paid: 1900,
          currency: 'usd',
          status: 'paid'
        }
      end

      let(:webhook_event) do
        create_stripe_webhook_event(
          type: 'invoice.payment_succeeded',
          data: invoice_data
        )
      end

      it 'processes the successful payment' do
        expect do
          post '/webhooks/stripe',
               params: webhook_event.to_json,
               headers: headers
        end.to change { stripe_customer.charges.count }.by(1)

        expect(response).to have_http_status(:ok)

        charge = stripe_customer.charges.last
        expect(charge.amount).to eq(1900)
        expect(charge.currency).to eq('usd')
      end
    end

    context 'invoice.payment_failed' do
      let!(:subscription) do
        stripe_customer.subscriptions.create!(
          name: 'monthly',
          processor_id: 'sub_test123',
          processor_plan: 'price_monthly_test',
          status: 'active',
          current_period_start: Time.current,
          current_period_end: 1.month.from_now
        )
      end

      let(:invoice_data) do
        {
          id: 'in_test123',
          customer: stripe_customer.processor_id,
          subscription: 'sub_test123',
          amount_due: 1900,
          currency: 'usd',
          status: 'open'
        }
      end

      let(:webhook_event) do
        create_stripe_webhook_event(
          type: 'invoice.payment_failed',
          data: invoice_data
        )
      end

      it 'handles the failed payment' do
        post '/webhooks/stripe',
             params: webhook_event.to_json,
             headers: headers

        expect(response).to have_http_status(:ok)
        # You can add specific logic here for handling failed payments
        # such as sending notifications, updating subscription status, etc.
      end
    end

    context 'with invalid signature' do
      before do
        allow(Stripe::Webhook).to receive(:construct_event).and_raise(
          Stripe::SignatureVerificationError.new('Invalid signature', 'sig_header')
        )
      end

      let(:webhook_event) { {} }

      it 'returns unauthorized status' do
        post '/webhooks/stripe',
             params: webhook_event.to_json,
             headers: headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
