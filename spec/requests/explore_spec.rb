# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Explore', type: :request do
  # ---- Shared setup ----

  let!(:lounge_owner) { create(:lounge_owner) }

  let!(:public_lounge) do
    create(:lounge, lounge_owner: lounge_owner, publicly_listed: true)
  end

  let!(:private_lounge) do
    create(:lounge, lounge_owner: lounge_owner, publicly_listed: false)
  end

  let!(:public_event) do
    create(:event, lounge: public_lounge, date: 1.week.from_now)
  end

  let!(:private_event) do
    create(:event, lounge: private_lounge, name: 'Private Lounge Event', date: 1.week.from_now)
  end

  let!(:past_event) do
    event = create(:event, lounge: public_lounge, date: 1.week.from_now)
    event.update_column(:date, 1.week.ago)
    event
  end

  let!(:public_offer) do
    create(:special_offer, lounge: public_lounge,
                           start_date: Date.current, end_date: 1.month.from_now)
  end

  let!(:private_offer) do
    create(:special_offer, lounge: private_lounge,
                           name: 'Private Lounge Deal',
                           start_date: Date.current, end_date: 1.month.from_now)
  end

  # ---- GET /explore ----

  describe 'GET /explore' do
    it 'returns a successful response' do
      get explore_path
      expect(response).to have_http_status(:ok)
    end

    it 'shows events from publicly listed lounges only' do
      get explore_path
      expect(response.body).to include(public_event.name)
      expect(response.body).not_to include(private_event.name)
    end

    it 'does not show past events' do
      get explore_path
      expect(response.body).not_to include(past_event.name)
    end

    it 'shows special offers from publicly listed lounges only' do
      get explore_path
      expect(response.body).to include(public_offer.name)
      expect(response.body).not_to include(private_offer.name)
    end

    it 'shows publicly listed lounges' do
      get explore_path
      expect(response.body).to include(public_lounge.name)
      expect(response.body).not_to include(private_lounge.name)
    end

    it 'does not require authentication' do
      get explore_path
      expect(response).not_to redirect_to(new_lounge_owner_session_path)
    end
  end

  # ---- GET /explore/events/:id ----

  describe 'GET /explore/events/:id' do
    it 'shows a public event' do
      get explore_event_path(public_event)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(public_event.name)
      expect(response.body).to include(public_lounge.name)
    end

    it 'returns 404 for events from private lounges' do
      get explore_event_path(private_event)
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for past events' do
      get explore_event_path(past_event)
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for private lounges' do
      get explore_lounge_path(private_lounge)
      expect(response).to have_http_status(:not_found)
    end

    context 'when the event has a capacity' do
      let!(:capped_event) do
        create(:event, lounge: public_lounge, date: 2.weeks.from_now, capacity: 50)
      end

      it 'shows spots remaining' do
        get explore_event_path(capped_event)
        expect(response.body).to include('spots remaining')
      end
    end
  end

  # ---- GET /explore/lounges/:id ----

  describe 'GET /explore/lounges/:id' do
    it 'shows a publicly listed lounge' do
      get explore_lounge_path(public_lounge)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(public_lounge.name)
    end

    it 'shows upcoming events for the lounge' do
      get explore_lounge_path(public_lounge)
      expect(response.body).to include(public_event.name)
    end

    it 'shows current offers for the lounge' do
      get explore_lounge_path(public_lounge)
      expect(response.body).to include(public_offer.name)
    end

    it 'returns 404 for private lounges' do
      get explore_lounge_path(private_lounge)
      expect(response).to have_http_status(:not_found)
    end
  end
end
