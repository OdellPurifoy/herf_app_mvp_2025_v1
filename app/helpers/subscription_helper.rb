# frozen_string_literal: true

module SubscriptionHelper
  def can_create_lounge?
    lounge_owner_signed_in? && current_lounge_owner.subscriptions.active.any?
  end

  def subscription_status
    if lounge_owner_signed_in?
      current_lounge_owner.subscriptions.active.any? ? 'Active' : 'Inactive'
    else
      'Not subscribed'
    end
  end

  def subscription_name
    return unless lounge_owner_signed_in? && current_lounge_owner.subscriptions.active.any?

    subscription = current_lounge_owner.subscriptions.active.first
    subscription.name.capitalize
  end
end
