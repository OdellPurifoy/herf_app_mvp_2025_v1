# frozen_string_literal: true

class ExploreController < ApplicationController
  def index
    @events = Event.browsable
                   .includes(lounge: { logo_attachment: :blob })
                   .page(params[:page])
                   .per(9)

    @special_offers = SpecialOffer.browsable
                                  .includes(lounge: { logo_attachment: :blob })
                                  .page(params[:offers_page])
                                  .per(6)

    @lounges = Lounge.publicly_listed
                     .includes(logo_attachment: :blob)
                     .order(:name)
  end

  def show_event
    @event = Event.browsable.find(params[:id])
    @lounge = @event.lounge
    @spots_remaining = spots_remaining(@event)
  end

  def show_lounge
    @lounge = Lounge.publicly_listed.find(params[:id])
    @upcoming_events = @lounge.events.upcoming.limit(6)
    @current_offers = @lounge.special_offers.upcoming.limit(6)
  end

  private

  def spots_remaining(event)
    return nil unless event.capacity.present?

    member_attendees = event.total_confirmed_attendees
    public_registered = event.total_registered_public_guests
    remaining = event.capacity - member_attendees - public_registered
    [remaining, 0].max
  end
end
