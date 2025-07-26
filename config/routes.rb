# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :lounge_owners
  resources :lounges do
    resources :events, shallow: true
    resources :special_offers, shallow: true
    resources :memberships, shallow: true
  end

  # Subscription routes
  resource :subscription, only: %i[new create] do
    get 'success'
    get 'cancel'
    get 'billing_portal'
  end

  root 'home#index'
  get 'up' => 'rails/health#show', as: :rails_health_check
  get 'dashboard' => 'dashboard#index'
end
