# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name date_of_birth phone_number])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[first_name last_name date_of_birth phone_number])
  end

  def after_sign_in_path_for(_resource)
    dashboard_path
  end

  def check_subscription
    return true if lounge_owner_signed_in? && current_lounge_owner.subscriptions.active.any?

    flash[:alert] = 'You need an active subscription to access this feature.'
    redirect_to dashboard_path
    false
  end

  def after_sign_up_path_for(_resource)
    dashboard_path
  end
end
