# frozen_string_literal: true

class MembershipsController < ApplicationController
  before_action :authenticate_lounge_owner!
  before_action :set_membership, only: %i[show edit update destroy]
  before_action :set_lounge, only: %i[index new create]

  def index
    @memberships = @lounge.memberships
  end

  def show; end

  def new
    @membership = @lounge.memberships.build
  end

  def create
    @membership = @lounge.memberships.build(membership_params)
    if @membership.save
      redirect_to lounge_memberships_path, notice: 'Membership was successfully created.'
    else
      render :new
    end
  end

  def edit; end

  def update
    if @membership.update(membership_params)
      redirect_to lounge_memberships_path, notice: 'Membership was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @membership.destroy
    redirect_to lounge_memberships_path(@membership.lounge), notice: 'Membership was successfully destroyed.'
  end

  private

  def set_membership
    @membership = Membership.find(params[:id])
  end

  def set_lounge
    @lounge = Lounge.find(params[:lounge_id])
  end

  def membership_params
    params.require(:membership).permit(:first_name, :last_name, :email, :phone_number, :opt_out_text_messaging,
                                       :allow_text_notifications, :allow_email_notifications)
  end
end
