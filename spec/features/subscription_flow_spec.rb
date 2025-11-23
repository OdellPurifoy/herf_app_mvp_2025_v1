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

  scenario 'User subscribes to robusto plan' do
    visit root_path

    # Navigate to pricing
    first(:link, 'Pricing').click

    # Select robusto plan
    click_link 'Subscribe Now', href: /plan=robusto_monthly/

    # Should go to subscription form with robusto plan
    expect(page).to have_current_path(new_subscription_path(plan: 'robusto_monthly'))
    expect(page).to have_content('Robusto')
  end

  scenario 'User subscribes to churchill plan' do
    visit root_path

    # Navigate to pricing
    first(:link, 'Pricing').click

    # Select churchill plan
    click_link 'Subscribe Now', href: /plan=churchill_monthly/

    # Should go to subscription form with churchill plan
    expect(page).to have_current_path(new_subscription_path(plan: 'churchill_monthly'))
    expect(page).to have_content('Churchill')
  end

  scenario 'User returns from successful subscription' do
    visit success_subscription_path

    expect(page).to have_content('subscription is active')
    expect(page).to have_current_path(dashboard_path)
  end

  scenario 'User cancels subscription process' do
    visit cancel_subscription_path

    expect(page).to have_content('Your subscription was not completed')
    expect(page).to have_current_path(root_path)
  end

  context 'with existing subscription' do
    let(:subscribed_owner) { create(:lounge_owner, :with_subscription) }

    before do
      sign_in subscribed_owner
      stub_stripe_billing_portal_session_create
    end

    scenario 'User accesses billing portal' do
      visit billing_portal_subscription_path

      # Should redirect to the billing portal (in test env this will be a test session ID)
      expect(page).to have_current_path(%r{/session/bps_})
    end

    scenario 'User can create lounge with active subscription' do
      visit dashboard_path

      expect(page).to have_content('Create Lounge')
      # Should not show subscription warning
      expect(page).not_to have_content('need an active subscription')
    end
  end
end
