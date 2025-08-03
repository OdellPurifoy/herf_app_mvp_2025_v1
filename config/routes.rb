# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :lounge_owners
  resources :lounges do
    resources :events, shallow: true do
      resources :rsvps, only: [:index], shallow: true
    end
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

  # RSVP routes with token-based authentication
  get 'rsvp/:token', to: 'rsvps#show', as: :rsvp
  patch 'rsvp/:token', to: 'rsvps#update'
  put 'rsvp/:token', to: 'rsvps#update'

  # Mount Pay engine for Stripe webhooks - at the end
  # mount Pay::Engine, at: '/pay'
end
