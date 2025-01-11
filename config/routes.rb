# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :lounge_owners
  resources :lounges do
    resources :events, shallow: true
  end
  root 'home#index'
  get 'up' => 'rails/health#show', as: :rails_health_check
  get 'dashboard' => 'dashboard#index'
end
