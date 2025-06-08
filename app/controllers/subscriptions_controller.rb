# frozen_string_literal: true

class SubscriptionsController < ApplicationController
  before_action :authenticate_lounge_owner!

  def new
    @plan = SubscriptionPlan.find(params[:plan])
  end

  def create
    @plan = SubscriptionPlan.find(params[:plan])

    # Create the Stripe Checkout session
    checkout_session = current_lounge_owner.payment_processor.checkout(
      mode: 'subscription',
      line_items: [{
        price: @plan[:stripe_price_id],
        quantity: 1
      }],
      success_url: success_subscription_url,
      cancel_url: cancel_subscription_url
    )

    redirect_to checkout_session.url, allow_other_host: true
  end

  def success
    flash[:notice] = 'Your subscription is active. You can now create your lounge!'
    redirect_to dashboard_path
  end

  def cancel
    flash[:alert] = 'Your subscription was not completed.'
    redirect_to root_path
  end

  def billing_portal
    portal_session = current_lounge_owner.payment_processor.billing_portal
    redirect_to portal_session.url, allow_other_host: true
  end
end
