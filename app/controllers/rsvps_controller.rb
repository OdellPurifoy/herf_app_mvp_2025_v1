# frozen_string_literal: true

class RsvpsController < ApplicationController
  before_action :authenticate_lounge_owner!, only: [:index]
  before_action :find_event_and_authorize, only: [:index]
  before_action :find_rsvp_by_token, only: %i[show update]
  before_action :validate_rsvp_token, only: %i[show update]
  before_action :handle_expired_rsvp, only: %i[show]

  # GET /events/:event_id/rsvps
  def index
    @rsvps = @event.rsvps.includes(:membership).order(:status, 'memberships.first_name')
    @rsvp_summary = @event.rsvp_summary
  end

  # GET /rsvp/:token
  def show
    @event = @rsvp.event
    @membership = @rsvp.membership
    @guest_count_options = (1..10).to_a
  end

  # PATCH/PUT /rsvp/:token
  def update
    if @rsvp.expired?
      redirect_to rsvp_path(@rsvp.rsvp_token),
                  alert: 'This RSVP has expired and can no longer be updated.'
      return
    end

    if @rsvp.valid_for_response?
      if @rsvp.respond_with(rsvp_params[:status], rsvp_params[:guest_count])
        redirect_to rsvp_path(@rsvp.rsvp_token),
                    notice: rsvp_success_message
      else
        render :show, status: :unprocessable_entity
      end
    else
      redirect_to rsvp_path(@rsvp.rsvp_token),
                  alert: 'This RSVP has expired and can no longer be updated.'
    end
  end

  private

  def find_event_and_authorize
    @event = Event.find(params[:event_id])

    # Ensure the event belongs to the current lounge owner's lounge
    return if current_lounge_owner.lounges.include?(@event.lounge)

    redirect_to dashboard_path, alert: 'Access denied.'
  end

  def find_rsvp_by_token
    @rsvp = Rsvp.find_by_token(params[:token])
  end

  def validate_rsvp_token
    return if @rsvp

    render file: Rails.root.join('public', '404.html'),
           status: :not_found,
           layout: false
  end

  def handle_expired_rsvp
    return unless @rsvp&.expired?

    @error_message = 'This RSVP link has expired.'
    render :expired, status: :gone
  end

  def rsvp_params
    params.require(:rsvp).permit(:status, :guest_count)
  end

  def rsvp_success_message
    case @rsvp.status
    when 'attending'
      guest_text = @rsvp.guest_count == 1 ? 'guest' : 'guests'
      "Great! You've confirmed your attendance for #{@rsvp.guest_count} #{guest_text}."
    when 'declined'
      "Thanks for letting us know you won't be able to make it."
    else
      'Your RSVP has been updated.'
    end
  end
end
