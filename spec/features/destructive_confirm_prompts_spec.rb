# frozen_string_literal: true

require 'rails_helper'

# rack_test does not execute JavaScript, so it never honours
# `data-turbo-confirm` -- these specs prove the attribute is rendered on the
# real pages, and that the destroy path still works once confirmed.
RSpec.describe 'Destructive confirmation prompts', type: :feature do
  let(:lounge_owner) { FactoryBot.create(:lounge_owner, :with_subscription) }
  let(:lounge) { FactoryBot.create(:lounge, lounge_owner: lounge_owner) }

  # Built from the route helper so a Devise path change doesn't silently stop
  # this from matching anything.
  let(:sign_out_button) do
    "form[action=\"#{destroy_lounge_owner_session_path}\"] button[data-turbo-confirm=\"Are you sure?\"]"
  end

  before { sign_in lounge_owner }

  describe 'events index' do
    let!(:event) do
      FactoryBot.create(:event,
                        lounge: lounge,
                        date: 1.week.from_now.to_date,
                        start_time: Time.zone.today + 1.week + 7.hours,
                        end_time: Time.zone.today + 1.week + 9.hours)
    end

    it 'renders the Delete button with a Turbo confirmation' do
      visit lounge_events_path(lounge)

      expect(page).to have_css('button[data-turbo-confirm="Are you sure?"]', text: 'Delete')
      expect(page).to have_no_css('[data-confirm]')
    end
  end

  describe 'special offers index' do
    let!(:special_offer) { FactoryBot.create(:special_offer, lounge: lounge) }

    it 'renders the Delete button with a Turbo confirmation' do
      visit lounge_special_offers_path(lounge)

      expect(page).to have_css('button[data-turbo-confirm="Are you sure?"]', text: 'Delete')
      expect(page).to have_no_css('[data-confirm]')
    end
  end

  describe 'memberships index' do
    let!(:membership) { FactoryBot.create(:membership, lounge: lounge) }

    before { visit lounge_memberships_path(lounge) }

    it 'renders the Delete button with a Turbo confirmation' do
      expect(page).to have_css('button[data-turbo-confirm="Are you sure?"]', text: 'Delete')
      expect(page).to have_no_css('[data-confirm]')
    end

    it 'still destroys the membership when the delete is submitted' do
      expect { click_button 'Delete', match: :first }.to change(Membership, :count).by(-1)

      expect(Membership.exists?(membership.id)).to be(false)
      expect(page).to have_content('Membership was successfully destroyed.')
    end
  end

  describe 'dashboard' do
    it 'renders the sign out control with a Turbo confirmation' do
      visit dashboard_path

      expect(page).to have_css(sign_out_button)
      expect(page).to have_no_css('[data-confirm]')
    end
  end

  describe 'account settings' do
    it 'renders exactly one Turbo confirmation on Cancel my account' do
      visit edit_lounge_owner_registration_path

      # The legacy key was dropped here, so there must be one prompt, not two
      # attributes fighting over the same button.
      expect(page).to have_css('button[data-turbo-confirm="Are you sure?"]', text: 'Cancel my account', count: 1)
      expect(page).to have_no_css('[data-confirm]')
    end
  end

  describe 'sign out' do
    before { visit lounge_memberships_path(lounge) }

    it 'renders the sign out control with a Turbo confirmation' do
      expect(page).to have_css(sign_out_button)
    end

    it 'still ends the session when the sign out is submitted' do
      first(sign_out_button).click

      # The session is really gone, not just redirected away from: an
      # authenticated page now bounces to the sign-in form.
      visit dashboard_path

      expect(page).to have_current_path(new_lounge_owner_session_path)
      expect(page).to have_no_content(lounge_owner.email)
    end
  end
end
