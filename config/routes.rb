Rails.application.routes.draw do
  devise_for :lounge_owners
  root 'home#index'
  get 'up' => 'rails/health#show', as: :rails_health_check
  get 'dashboard' => 'dashboard#index'
end
