# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'RSVP Dashboard Integration', type: :feature do
  let(:lounge_owner) { FactoryBot.create(:lounge_owner, :with_subscription) }
  let(:lounge) { FactoryBot.create(:lounge, lounge_owner: lounge_owner) }
  let(:event_with_rsvp) do
    FactoryBot.create(:event,
                      lounge: lounge,
                      date: 1.week.from_now.to_date,
                      start_time: Time.zone.today + 1.week + 7.hours,
                      end_time: Time.zone.today + 1.week + 9.hours,
                      rsvp_needed: true)
  end
  let(:event_without_rsvp) do
    FactoryBot.create(:event,
                      lounge: lounge,
                      date: 2.weeks.from_now.to_date,
                      start_time: Time.zone.today + 2.weeks + 7.hours,
                      end_time: Time.zone.today + 2.weeks + 9.hours,
                      rsvp_needed: false)
  end

  before do
    # Create memberships first
    @memberships = []
    6.times do
      @memberships << FactoryBot.create(:membership, lounge: lounge)
    end

    # Create the event with RSVP needed (this will auto-create RSVPs for all memberships)
    event_with_rsvp

    # Update RSVP statuses
    rsvps = event_with_rsvp.rsvps.reload

    # Set 3 to attending
    rsvps.limit(3).update_all(status: Rsvp.statuses[:attending])

    # Set next 2 to pending (they should already be pending by default)
    rsvps.offset(3).limit(2).update_all(status: Rsvp.statuses[:pending])

    # Set last 1 to declined
    rsvps.offset(5).limit(1).update_all(status: Rsvp.statuses[:declined])

    sign_in lounge_owner
  end

  scenario 'Dashboard shows RSVP status for events with RSVP enabled' do
    visit dashboard_path

    expect(page).to have_content('RSVP Status')
    expect(page).to have_content('3')  # attending count
    expect(page).to have_content('Attending')
    expect(page).to have_content('2')  # pending count
    expect(page).to have_content('Pending')
    expect(page).to have_content('1')  # declined count
    expect(page).to have_content('Declined')
    expect(page).to have_content('Response Rate')
  end

  scenario 'Dashboard does not show RSVP status for events without RSVP' do
    event_with_rsvp.destroy! # Remove the RSVP event, leaving only non-RSVP event

    visit dashboard_path

    expect(page).not_to have_content('RSVP Status')
    expect(page).not_to have_content('Attending')
    expect(page).not_to have_content('Response Rate')
  end

  scenario 'Lounge owner can view detailed RSVP management page' do
    visit dashboard_path

    click_link 'View RSVPs'

    expect(page).to have_content('RSVP Management')
    expect(page).to have_content(event_with_rsvp.name)
    expect(page).to have_content('Member')
    expect(page).to have_content('Status')
    expect(page).to have_content('Guest Count')

    # Should show all RSVPs
    expect(page).to have_selector('tbody tr', count: 6) # 3 attending + 2 pending + 1 declined
  end
end
