# frozen_string_literal: true

# app/controllers/admins/registrations_controller.rb
module Admins
  class RegistrationsController < Devise::RegistrationsController
    # Override if needed

    # Only allow certain parameters
    private

    def sign_up_params
      params.require(:admin).permit(:email, :password, :password_confirmation)
    end
  end
end
