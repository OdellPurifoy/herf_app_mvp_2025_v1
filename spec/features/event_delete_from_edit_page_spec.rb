# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Deleting an event from the edit page', type: :feature do
  let(:lounge_owner) { FactoryBot.create(:lounge_owner, :with_subscription) }
  let(:lounge) { FactoryBot.create(:lounge, lounge_owner: lounge_owner) }
  let!(:membership) { FactoryBot.create(:membership, lounge: lounge) }
  let!(:event) do
    FactoryBot.create(:event,
                      lounge: lounge,
                      date: 1.week.from_now.to_date,
                      start_time: Time.zone.today + 1.week + 7.hours,
                      end_time: Time.zone.today + 1.week + 9.hours)
  end

  before do
    sign_in lounge_owner
    visit edit_event_path(event)
  end

  scenario 'Delete Event button carries the Turbo confirmation prompt' do
    expect(page).to have_css(
      'button[data-turbo-confirm="Are you sure you want to delete this event?"]',
      text: 'Delete Event'
    )
  end

  scenario 'clicking Delete Event destroys the event and redirects to the dashboard' do
    expect { click_button 'Delete Event' }.to change(Event, :count).by(-1)

    expect(Event.exists?(event.id)).to be(false)
    expect(page).to have_current_path(dashboard_path)
    expect(page).to have_content('Event was successfully destroyed.')
  end

  scenario 'clicking Delete Event enqueues the deletion notification jobs' do
    expected_payload = hash_including(id: event.id, name: event.name, member_ids: [membership.id])

    expect { click_button 'Delete Event' }
      .to have_enqueued_job(EventDeletionNotificationJob).with(expected_payload)
      .and have_enqueued_job(EventDeletionEmailNotificationJob).with(expected_payload)
  end
end
