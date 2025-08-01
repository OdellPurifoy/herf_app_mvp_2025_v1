# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Subscription Flow', type: :feature do
  include StripeHelpers

  let(:lounge_owner) { create(:lounge_owner) }

  before do
    sign_in lounge_owner
    stub_stripe_customer_create
    stub_stripe_checkout_session_create
  end

  scenario 'User subscribes to monthly plan' do
    visit root_path

    # Navigate to pricing
    click_link 'Pricing'

    # Select monthly plan
    within '[aria-describedby="tier-monthly"]' do
      click_link 'Subscribe Now'
    end

    # Should redirect to Stripe checkout
    expect(page).to have_current_path(/checkout\.stripe\.com/)
  end

  scenario 'User subscribes to yearly plan' do
    visit root_path

    # Navigate to pricing
    click_link 'Pricing'

    # Select yearly plan
    within '[aria-describedby="tier-yearly"]' do
      click_link 'Subscribe Now'
    end

    # Should redirect to Stripe checkout
    expect(page).to have_current_path(/checkout\.stripe\.com/)
  end

  scenario 'User returns from successful subscription' do
    visit subscription_success_path

    expect(page).to have_content('subscription is active')
    expect(page).to have_current_path(dashboard_path)
  end

  scenario 'User cancels subscription process' do
    visit subscription_cancel_path

    expect(page).to have_content('not completed')
    expect(page).to have_current_path(root_path)
  end

  context 'with existing subscription' do
    let(:subscribed_owner) { create(:lounge_owner, :with_subscription) }

    before do
      sign_in subscribed_owner
      stub_stripe_billing_portal_session_create
    end

    scenario 'User accesses billing portal' do
      visit dashboard_path
      click_link 'Billing Portal' # Assuming you have this link

      # Should redirect to Stripe billing portal
      expect(page).to have_current_path(/billing\.stripe\.com/)
    end

    scenario 'User can create lounge with active subscription' do
      visit dashboard_path

      expect(page).to have_content('Create Lounge')
      # Should not show subscription warning
      expect(page).not_to have_content('need an active subscription')
    end
  end
end
