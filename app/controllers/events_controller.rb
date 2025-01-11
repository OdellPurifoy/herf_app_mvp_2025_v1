class EventsController < ApplicationController
  before_action :authenticate_lounge_owner!
  before_action :set_event, only: %i[show edit update destroy]
  before_action :set_lounge, only: %i[new create]

  def index
    @events = Event.all
  end

  def show
  end

  def new
    @event = @lounge.events.build
  end

  def create
    @event = @lounge.events.build(event_params)
    if @event.save
      redirect_to dashboard_path, notice: 'Event was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @event.update(event_params)
      redirect_to dashboard_path, notice: 'Event was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @event.destroy
    redirect_to events_url, notice: 'Event was successfully destroyed.'
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def set_lounge
    @lounge = Lounge.find(params[:lounge_id])
  end

  def event_params
    params.require(:event).permit(:name, :event_type, :date, :start_time, :end_time, :description, :virtual,
                                  :members_only, :rsvp_needed, :capacity, :entry_fee, :flyer)
  end
end
