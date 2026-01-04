# frozen_string_literal: true

class LoungesController < ApplicationController
  before_action :authenticate_lounge_owner!, except: %i[index show]
  before_action :set_lounge, only: %i[show edit update destroy]
  before_action :check_subscription, only: %i[new create]

  def index
    @lounges = Lounge.all
  end

  def show
    @lounge = Lounge.find(params[:id])
  end

  def new
    @lounge = Lounge.new
  end

  def create
    @lounge = current_lounge_owner.lounges.build(lounge_params)
    if @lounge.save
      respond_to do |format|
        format.html { redirect_to dashboard_path, notice: 'Lounge was successfully created.' }
        format.turbo_stream { redirect_to dashboard_path, notice: 'Lounge was successfully created.' }
      end
    else
      render :new
    end
  end

  def edit
    @lounge = Lounge.find(params[:id])
  end

  def update
    @lounge = Lounge.find(params[:id])
    if @lounge.update(lounge_params)
      respond_to do |format|
        format.html { redirect_to dashboard_path, notice: 'Lounge was successfully updated.' }
        format.turbo_stream { redirect_to dashboard_path, notice: 'Lounge was successfully updated.' }
      end
    else
      render :edit
    end
  end

  def destroy
    @lounge = Lounge.find(params[:id])
    @lounge.destroy
    redirect_to dashboard_path, notice: 'Lounge was successfully destroyed.'
  end

  private

  def set_lounge
    @lounge = Lounge.find(params[:id])
  end

  def lounge_params
    params.require(:lounge).permit(:name, :address_street_1, :address_street_2, :city, :state, :zip_code,
                                   :phone_number, :email, :description, :facebook_handle, :x_handle,
                                   :instagram_handle, :outside_cigars_allowed, :outside_food_allowed,
                                   :alcohol_served, :outside_alcohol_allowed, :food_served, :website, :logo, :cover_image)
  end

  def check_subscription
    return if current_lounge_owner.subscriptions.active.any?

    flash[:alert] = 'You need an active subscription to create a lounge.'
    redirect_to root_path
  end
end
