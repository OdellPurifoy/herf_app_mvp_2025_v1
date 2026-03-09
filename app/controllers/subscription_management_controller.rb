# frozen_string_literal: true

class SubscriptionManagementController < ApplicationController
  # Temporary controller for granting subscriptions in production
  # TODO: Remove this after initial setup
  before_action :verify_admin_token
  skip_before_action :verify_authenticity_token

  def grant
    email = params[:email]
    plan = params[:plan] || 'robusto_monthly'

    lounge_owner = LoungeOwner.find_by(email: email)

    return render json: { error: "Lounge owner not found: #{email}" }, status: :not_found unless lounge_owner

    # Create Stripe customer if doesn't exist
    unless lounge_owner.payment_processor
      lounge_owner.set_payment_processor :stripe
      lounge_owner.payment_processor.update(
        processor_id: "cus_free_#{SecureRandom.hex(8)}"
      )
    end

    customer = lounge_owner.payment_processor

    # Cancel existing subscriptions
    customer.subscriptions.active.each(&:cancel) if customer.subscriptions.active.any?

    # Get the price ID
    price_id = if plan == 'churchill_monthly'
                 ENV.fetch('STRIPE_CHURCHILL_MONTHLY_PRICE_ID')
               else
                 ENV.fetch('STRIPE_ROBUSTO_MONTHLY_PRICE_ID')
               end

    # Create subscription with trial
    subscription = customer.subscriptions.create!(
      name: plan,
      processor_id: "sub_free_#{SecureRandom.hex(8)}",
      processor_plan: price_id,
      trial_ends_at: 1.year.from_now,
      status: 'active',
      current_period_start: Time.current,
      current_period_end: 1.year.from_now
    )

    render json: {
      success: true,
      message: "Subscription granted to #{email}",
      subscription: {
        plan: subscription.name,
        status: subscription.status,
        trial_ends_at: subscription.trial_ends_at
      }
    }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def list
    owners = LoungeOwner.all.map do |owner|
      subscription_info = if owner.payment_processor&.subscriptions&.active&.any?
                            sub = owner.payment_processor.subscriptions.active.first
                            { subscribed: true, plan: sub.name, status: sub.status }
                          else
                            { subscribed: false }
                          end

      {
        email: owner.email,
        name: owner.full_name,
        subscription: subscription_info
      }
    end

    render json: { lounge_owners: owners, total: owners.count }
  end

  private

  def verify_admin_token
    token = request.headers['X-Admin-Token'] || params[:admin_token]
    expected_token = ENV['ADMIN_TOKEN']

    return if expected_token.present? && token == expected_token

    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end
