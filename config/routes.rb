# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  # Admin authentication routes
  devise_for :admins, skip: [:registrations], controllers: {
    sessions: 'admins/sessions'
  }

  # Alias for easier admin sign-in access
  get 'admins', to: redirect('/admins/sign_in')
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

  # Admin routes
  get 'admin' => 'admin_dashboard#index'
  get 'admin/lounge_owners' => 'admin_dashboard#lounge_owners'
  get 'admin/events' => 'admin_dashboard#events'
  get 'admin/rsvps' => 'admin_dashboard#rsvps'
  get 'admin/special_offers' => 'admin_dashboard#special_offers'
  post 'admin_member_upload' => 'admin_dashboard#member_upload'

  # Temporary subscription management (TODO: Remove after setup)
  get 'subscription_management/list', to: 'subscription_management#list'
  post 'subscription_management/grant', to: 'subscription_management#grant'

  # Public explore pages (no auth)
  get 'explore', to: 'explore#index', as: :explore
  get 'explore/events/:id', to: 'explore#show_event', as: :explore_event
  get 'explore/lounges/:id', to: 'explore#show_lounge', as: :explore_lounge

  resources :admin_dashboard, only: [:index]

  mount Sidekiq::Web => '/sidekiq'
end
