# app/controllers/admins/registrations_controller.rb
class Admins::RegistrationsController < Devise::RegistrationsController
  # Override if needed

  # Only allow certain parameters
  private

  def sign_up_params
    params.require(:admin).permit(:email, :password, :password_confirmation)
  end
end
