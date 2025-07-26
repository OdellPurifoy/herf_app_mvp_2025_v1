# frozen_string_literal: true

class WebhooksController < ApplicationController
  protect_from_forgery with: :null_session

  def stripe
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = ENV['STRIPE_SIGNING_SECRET']

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError
      render json: { error: 'Invalid payload' }, status: 400
      return
    rescue Stripe::SignatureVerificationError
      render json: { error: 'Invalid signature' }, status: 400
      return
    end

    # Handle the event
    case event['type']
    when 'customer.subscription.created'
      subscription = event['data']['object']
      handle_subscription_created(subscription)
    when 'customer.subscription.updated'
      subscription = event['data']['object']
      handle_subscription_updated(subscription)
    when 'customer.subscription.deleted'
      subscription = event['data']['object']
      handle_subscription_deleted(subscription)
    when 'invoice.payment_succeeded'
      invoice = event['data']['object']
      handle_payment_succeeded(invoice)
    when 'invoice.payment_failed'
      invoice = event['data']['object']
      handle_payment_failed(invoice)
    else
      Rails.logger.info "Unhandled event type: #{event['type']}"
    end

    render json: { message: 'success' }
  end

  private

  def handle_subscription_created(subscription)
    Rails.logger.info "Subscription created: #{subscription['id']}"
    # Find the customer and create/update subscription
    customer = Pay::Customer.find_by(processor_id: subscription['customer'])
    return unless customer

    customer.sync_subscriptions
  end

  def handle_subscription_updated(subscription)
    Rails.logger.info "Subscription updated: #{subscription['id']}"
    # Find the customer and update subscription
    customer = Pay::Customer.find_by(processor_id: subscription['customer'])
    return unless customer

    customer.sync_subscriptions
  end

  def handle_subscription_deleted(subscription)
    Rails.logger.info "Subscription deleted: #{subscription['id']}"
    # Find the customer and update subscription
    customer = Pay::Customer.find_by(processor_id: subscription['customer'])
    return unless customer

    customer.sync_subscriptions
  end

  def handle_payment_succeeded(invoice)
    Rails.logger.info "Payment succeeded: #{invoice['id']}"
  end

  def handle_payment_failed(invoice)
    Rails.logger.info "Payment failed: #{invoice['id']}"
  end
end
