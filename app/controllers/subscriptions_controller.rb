# frozen_string_literal: true

class SubscriptionsController < ApplicationController
  before_action :authenticate_lounge_owner!

  def new
    @plan = SubscriptionPlan.find(params[:plan])

    return unless @plan.nil?

    redirect_to root_path(anchor: 'pricing'), alert: 'Please select a subscription plan.'
    nil
  end

  def create
    @plan = SubscriptionPlan.find(params[:plan])

    if @plan.nil?
      redirect_to root_path(anchor: 'pricing'), alert: 'Please select a subscription plan.'
      return
    end

    begin
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
    rescue Stripe::CardError
      redirect_to root_path, alert: 'There was a problem with your subscription. Please try again.'
    rescue StandardError
      redirect_to root_path, alert: 'There was a problem with your subscription. Please try again.'
    end
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
    unless current_lounge_owner.subscribed?
      redirect_to root_path(anchor: 'pricing'), alert: 'You need an active subscription to access the billing portal.'
      return
    end

    portal_session = Stripe::BillingPortal::Session.create({
                                                             customer: current_lounge_owner.payment_processor.processor_id,
                                                             return_url: dashboard_url
                                                           })

    redirect_to portal_session.url, allow_other_host: true
  end
end
