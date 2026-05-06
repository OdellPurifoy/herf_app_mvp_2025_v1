# frozen_string_literal: true

class EventRegistrationsController < ApplicationController
  # No authentication — this is fully public

  before_action :set_event, only: %i[new create]

  def new
    @registration = EventRegistration.new
    @lounge = @event.lounge
    @spots_remaining = spots_remaining(@event)
  end

  def create
    @registration = @event.event_registrations.build(registration_params)

    if @registration.save
      EventRegistrationConfirmationJob.perform_later(@registration.id)
      notify_lounge_of_membership_interest(@registration)
      redirect_to registration_status_path(@registration.registration_token),
                  notice: "You're registered for #{@event.name}!"
    else
      @lounge = @event.lounge
      @spots_remaining = spots_remaining(@event)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @registration = EventRegistration.find_by!(registration_token: params[:token])
    @event = @registration.event
    @lounge = @event.lounge
  end

  private

  def set_event
    @event = Event.browsable.publicly_registerable.find(params[:id])
  end

  def registration_params
    params.require(:event_registration)
          .permit(:first_name, :last_name, :email,
                  :phone_number, :number_of_guests, :opt_in_to_membership)
  end

  def spots_remaining(event)
    return nil unless event.capacity.present?

    member_attendees = event.total_confirmed_attendees
    public_registered = event.total_registered_public_guests
    remaining = event.capacity - member_attendees - public_registered
    [remaining, 0].max
  end

  def notify_lounge_of_membership_interest(registration)
    return unless registration.opt_in_to_membership?

    MembershipInquiryMailer.inquiry_notification(registration).deliver_later
  end
end
