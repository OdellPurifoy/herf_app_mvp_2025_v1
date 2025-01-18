# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_lounge_owner!
  def index
    @lounge_owner = current_lounge_owner
    @lounge = @lounge_owner&.lounges&.first
    @upcoming_events = @lounge&.events&.upcoming
    @upcoming_special_offers = @lounge&.special_offers&.upcoming
  end
end
