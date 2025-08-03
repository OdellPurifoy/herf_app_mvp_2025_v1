# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RsvpsController, type: :controller do
  let(:lounge) { FactoryBot.create(:lounge) }
  let(:membership) { FactoryBot.create(:membership, lounge: lounge) }
  let(:event) do
    FactoryBot.create(:event,
                      lounge: lounge,
                      date: 1.week.from_now.to_date,
                      start_time: Time.zone.today + 1.week + 7.hours,
                      end_time: Time.zone.today + 1.week + 9.hours,
                      rsvp_needed: true)
  end
  let(:rsvp) { FactoryBot.create(:rsvp, event: event, membership: membership, expires_at: 1.day.from_now) }

  describe 'GET #show' do
    context 'with valid token' do
      it 'returns a successful response' do
        get :show, params: { token: rsvp.rsvp_token }
        expect(response).to be_successful
      end

      it 'assigns the correct RSVP' do
        get :show, params: { token: rsvp.rsvp_token }
        expect(assigns(:rsvp)).to eq(rsvp)
        expect(assigns(:event)).to eq(event)
        expect(assigns(:membership)).to eq(membership)
      end

      it 'assigns guest count options' do
        get :show, params: { token: rsvp.rsvp_token }
        expect(assigns(:guest_count_options)).to eq((1..10).to_a)
      end
    end

    context 'with invalid token' do
      it 'returns 404' do
        get :show, params: { token: 'invalid_token' }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with expired RSVP' do
      let(:expired_rsvp) { FactoryBot.create(:rsvp, :expired, event: event, membership: membership) }

      it 'renders the expired template' do
        get :show, params: { token: expired_rsvp.rsvp_token }
        expect(response).to have_http_status(:gone)
        expect(response).to render_template(:expired)
      end

      it 'assigns error message' do
        get :show, params: { token: expired_rsvp.rsvp_token }
        expect(assigns(:error_message)).to eq('This RSVP link has expired.')
      end
    end
  end

  describe 'PATCH #update' do
    context 'with valid token and valid for response' do
      context 'attending response' do
        let(:rsvp_params) { { status: 'attending', guest_count: '3' } }

        it 'updates the RSVP successfully' do
          patch :update, params: { token: rsvp.rsvp_token, rsvp: rsvp_params }

          rsvp.reload
          expect(rsvp.status).to eq('attending')
          expect(rsvp.guest_count).to eq(3)
        end

        it 'redirects with success message' do
          patch :update, params: { token: rsvp.rsvp_token, rsvp: rsvp_params }

          expect(response).to redirect_to(rsvp_path(rsvp.rsvp_token))
          expect(flash[:notice]).to include("You've confirmed your attendance for 3 guests")
        end
      end

      context 'declined response' do
        let(:rsvp_params) { { status: 'declined', guest_count: '1' } }

        it 'updates the RSVP successfully' do
          patch :update, params: { token: rsvp.rsvp_token, rsvp: rsvp_params }

          rsvp.reload
          expect(rsvp.status).to eq('declined')
        end

        it 'redirects with appropriate message' do
          patch :update, params: { token: rsvp.rsvp_token, rsvp: rsvp_params }

          expect(response).to redirect_to(rsvp_path(rsvp.rsvp_token))
          expect(flash[:notice]).to include("Thanks for letting us know you won't be able to make it")
        end
      end

      context 'with invalid parameters' do
        let(:invalid_params) { { status: 'attending', guest_count: '0' } }

        it 'does not update the RSVP' do
          original_status = rsvp.status
          patch :update, params: { token: rsvp.rsvp_token, rsvp: invalid_params }

          expect(rsvp.reload.status).to eq(original_status)
        end

        it 'renders the show template with errors' do
          patch :update, params: { token: rsvp.rsvp_token, rsvp: invalid_params }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:show)
        end
      end
    end

    context 'with expired RSVP' do
      let(:expired_rsvp) { FactoryBot.create(:rsvp, :expired, event: event, membership: membership) }
      let(:rsvp_params) { { status: 'attending', guest_count: '1' } }

      it 'does not update the RSVP' do
        original_status = expired_rsvp.status
        patch :update, params: { token: expired_rsvp.rsvp_token, rsvp: rsvp_params }

        expect(expired_rsvp.reload.status).to eq(original_status)
      end

      it 'redirects with error message' do
        patch :update, params: { token: expired_rsvp.rsvp_token, rsvp: rsvp_params }

        expect(response).to redirect_to(rsvp_path(expired_rsvp.rsvp_token))
        expect(flash[:alert]).to include('This RSVP has expired')
      end
    end

    context 'with invalid token' do
      it 'returns 404' do
        patch :update, params: { token: 'invalid_token', rsvp: { status: 'attending' } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'private methods' do
    describe '#rsvp_success_message' do
      it 'generates correct message for attending with 1 guest' do
        rsvp.update!(status: :attending, guest_count: 1)
        controller.instance_variable_set(:@rsvp, rsvp)

        message = controller.send(:rsvp_success_message)
        expect(message).to include('1 guest')
      end

      it 'generates correct message for attending with multiple guests' do
        rsvp.update!(status: :attending, guest_count: 3)
        controller.instance_variable_set(:@rsvp, rsvp)

        message = controller.send(:rsvp_success_message)
        expect(message).to include('3 guests')
      end

      it 'generates correct message for declined' do
        rsvp.update!(status: :declined)
        controller.instance_variable_set(:@rsvp, rsvp)

        message = controller.send(:rsvp_success_message)
        expect(message).to include("won't be able to make it")
      end
    end
  end
end
