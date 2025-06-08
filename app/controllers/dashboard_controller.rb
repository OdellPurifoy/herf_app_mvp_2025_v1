# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_lounge_owner!
  before_action :check_subscription, except: [:index]

  def index
    @lounge_owner = current_lounge_owner
    @lounge = @lounge_owner&.lounges&.first
    @upcoming_events = @lounge&.events&.upcoming
    @upcoming_special_offers = @lounge&.special_offers&.upcoming
    @has_active_subscription = current_lounge_owner.subscriptions.active.any?
  end

  private

  def check_subscription
    return if current_lounge_owner.subscriptions.active.any?

    flash[:alert] = 'You need an active subscription to access this feature.'
    redirect_to root_path
  end
end
