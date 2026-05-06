# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'EventRegistrations', type: :request do
  let!(:lounge_owner) { create(:lounge_owner) }
  let!(:lounge) { create(:lounge, lounge_owner: lounge_owner, publicly_listed: true) }

  let!(:event) do
    create(:event,
           lounge: lounge,
           date: 2.weeks.from_now,
           public_registrations_enabled: true,
           capacity: 50)
  end

  let(:valid_params) do
    {
      event_registration: {
        first_name: 'John',
        last_name: 'Doe',
        email: 'john.doe@example.com',
        phone_number: '5551234567',
        number_of_guests: 2,
        opt_in_to_membership: false
      }
    }
  end

  # ---- GET /explore/events/:id/register ----

  describe 'GET /explore/events/:id/register' do
    it 'returns a successful response' do
      get new_event_registration_path(event)
      expect(response).to have_http_status(:ok)
    end

    it 'does not require authentication' do
      get new_event_registration_path(event)
      expect(response).not_to redirect_to(new_lounge_owner_session_path)
    end

    it 'returns 404 for events without public registration' do
      event.update_column(:public_registrations_enabled, false)
      get new_event_registration_path(event)
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for events from private lounges' do
      lounge.update_column(:publicly_listed, false)
      get new_event_registration_path(event)
      expect(response).to have_http_status(:not_found)
    end
  end

  # ---- POST /explore/events/:id/register ----

  describe 'POST /explore/events/:id/register' do
    it 'creates a new event registration' do
      expect do
        post event_registrations_path(event), params: valid_params
      end.to change(EventRegistration, :count).by(1)
    end

    it 'redirects to the registration status page' do
      post event_registrations_path(event), params: valid_params
      registration = EventRegistration.last
      expect(response).to redirect_to(registration_status_path(registration.registration_token))
    end

    it 'enqueues a confirmation email job' do
      expect do
        post event_registrations_path(event), params: valid_params
      end.to have_enqueued_job(EventRegistrationConfirmationJob)
    end

    it 'sets number_of_guests to 0 by default when not provided' do
      params_without_guests = valid_params.deep_dup
      params_without_guests[:event_registration].delete(:number_of_guests)
      post event_registrations_path(event), params: params_without_guests
      expect(EventRegistration.last.number_of_guests).to eq(0)
    end

    context 'with invalid params' do
      it 'does not create a registration with missing email' do
        invalid_params = valid_params.deep_dup
        invalid_params[:event_registration][:email] = ''

        expect do
          post event_registrations_path(event), params: invalid_params
        end.not_to change(EventRegistration, :count)
      end

      it 'renders the form again with errors' do
        invalid_params = valid_params.deep_dup
        invalid_params[:event_registration][:email] = ''

        post event_registrations_path(event), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not allow duplicate email for the same event' do
        post event_registrations_path(event), params: valid_params

        expect do
          post event_registrations_path(event), params: valid_params
        end.not_to change(EventRegistration, :count)
      end
    end

    context 'when event is at full capacity' do
      before do
        event.update!(capacity: 3)
        create(:event_registration, event: event, number_of_guests: 2)
      end

      it 'does not allow registration exceeding capacity' do
        over_capacity_params = valid_params.deep_dup
        over_capacity_params[:event_registration][:number_of_guests] = 5

        expect do
          post event_registrations_path(event), params: over_capacity_params
        end.not_to change(EventRegistration, :count)
      end
    end

    context 'with membership inquiry opt-in' do
      it 'sends a membership inquiry email to the lounge owner when opted in' do
        opt_in_params = valid_params.deep_dup
        opt_in_params[:event_registration][:opt_in_to_membership] = true

        expect do
          post event_registrations_path(event), params: opt_in_params
        end.to have_enqueued_mail(MembershipInquiryMailer, :inquiry_notification)
      end

      it 'does not send a membership inquiry email when not opted in' do
        expect do
          post event_registrations_path(event), params: valid_params
        end.not_to have_enqueued_mail(MembershipInquiryMailer, :inquiry_notification)
      end

      it 'does not create a membership record regardless of opt-in' do
        opt_in_params = valid_params.deep_dup
        opt_in_params[:event_registration][:opt_in_to_membership] = true

        expect do
          post event_registrations_path(event), params: opt_in_params
        end.not_to change(Membership, :count)
      end
    end
  end

  # ---- GET /registration/:token ----

  describe 'GET /registration/:token' do
    let!(:registration) { create(:event_registration, event: event) }

    it 'shows the registration status page' do
      get registration_status_path(registration.registration_token)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(registration.full_name)
    end

    it 'returns 404 for invalid tokens' do
      get registration_status_path('nonexistent-token')
      expect(response).to have_http_status(:not_found)
    end
  end
end
