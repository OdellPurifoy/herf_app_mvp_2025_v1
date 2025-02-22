# frozen_string_literal: true

class SpecialOffersController < ApplicationController
  before_action :authenticate_lounge_owner!
  before_action :set_special_offer, only: %i[show edit update destroy]
  before_action :set_lounge, only: %i[index new create]

  def index
    @special_offers = @lounge&.special_offers&.order(start_date: :asc, end_date: :asc)&.page(params[:page])
  end

  def show; end

  def new
    @special_offer = @lounge.special_offers.build
  end

  def create
    @special_offer = @lounge.special_offers.build(special_offer_params)
    if @special_offer.save
      redirect_to lounge_special_offers_path(@lounge), notice: 'Special offer was successfully created.'
    else
      render :new
    end
  end

  def edit; end

  def update
    if @special_offer.update(special_offer_params)
      redirect_to lounge_special_offers_path(current_lounge_owner.lounges.first),
                  notice: 'Special offer was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @special_offer.destroy
    redirect_to special_offers_url, notice: 'Special offer was successfully destroyed.'
  end

  private

  def set_special_offer
    @special_offer = SpecialOffer.find(params[:id])
  end

  def set_lounge
    @lounge = Lounge.find(params[:lounge_id])
  end

  def special_offer_params
    params.require(:special_offer).permit(:name, :offer_type, :start_date, :end_date, :members_only, :offer_code,
                                          :description, :flyer)
  end
end
