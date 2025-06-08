# frozen_string_literal: true

class SpecialOffersController < ApplicationController
  before_action :authenticate_lounge_owner!
  before_action :check_subscription
  before_action :set_special_offer, only: %i[show edit update destroy]
  before_action :set_lounge, only: %i[index new create]

  def index
    @q = @lounge&.special_offers&.ransack(params[:q])
    @special_offers = @q&.result(distinct: true)&.order(start_date: :asc, end_date: :asc)&.page(params[:page])
  end

  def show; end

  def new
    @special_offer = @lounge.special_offers.build
  end

  def create
    @special_offer = @lounge.special_offers.build(special_offer_params)
    if @special_offer.save
      redirect_to lounge_special_offers_path(@lounge), notice: 'Special offer was successfully created.'
      new_special_offer_mailer
    else
      render :new
    end
  end

  def edit; end

  def update
    if @special_offer.update(special_offer_params)
      redirect_to lounge_special_offers_path(current_lounge_owner.lounges.first),
                  notice: 'Special offer was successfully updated.'
      updated_special_offer_mailer
    else
      render :edit
    end
  end

  def destroy
    cancelled_special_offer_mailer
    @special_offer.destroy
    redirect_to lounge_special_offers_path, notice: 'Special offer was successfully destroyed.'
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

  def new_special_offer_mailer
    @members = @special_offer.lounge.memberships.where(allow_email_notifications: true)

    @members.each do |member|
      NewSpecialOfferMailer.with(member: member, special_offer: @special_offer).notify.deliver_now
    end
  end

  def updated_special_offer_mailer
    @members = @special_offer.lounge.memberships.where(allow_email_notifications: true)

    @members.each do |member|
      UpdatedSpecialOfferMailer.with(member: member, special_offer: @special_offer).notify.deliver_now
    end
  end

  def cancelled_special_offer_mailer
    @members = @special_offer.lounge.memberships.where(allow_email_notifications: true)

    @members.each do |member|
      CancelledSpecialOfferMailer.with(member: member, special_offer: @special_offer).notify.deliver_now
    end
  end
end
