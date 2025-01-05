class DashboardController < ApplicationController
  before_action :authenticate_lounge_owner!
  def index
    @lounge_owner = current_lounge_owner
    @lounge = @lounge_owner&.lounges&.first
  end
end
