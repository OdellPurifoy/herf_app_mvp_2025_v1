# frozen_string_literal: true

class MembershipsController < ApplicationController
  before_action :authenticate_lounge_owner!
  before_action :check_subscription
  before_action :set_membership, only: %i[show edit update destroy]
  before_action :set_lounge, only: %i[index new create]

  def index
    @q = @lounge&.memberships&.ransack(params[:q])
    @memberships = @q&.result(distinct: true)&.order(last_name: :asc, first_name: :asc)&.page(params[:page])
  end

  def show; end

  def new
    @membership = @lounge.memberships.build
  end

  def create
    @membership = @lounge.memberships.build(membership_params)
    if @membership.save
      new_membership_mailer
      respond_to do |format|
        format.html { redirect_to lounge_memberships_path, notice: 'Membership was successfully created.' }
        format.turbo_stream { redirect_to lounge_memberships_path, notice: 'Membership was successfully created.' }
      end
    else
      flash.now[:alert] = @membership.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @membership.update(membership_params)
      updated_membership_mailer
      redirect_to lounge_memberships_path(@membership.lounge), notice: 'Membership was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    cancelled_membership_mailer
    @membership.destroy
    redirect_to dashboard_path, notice: 'Membership was successfully destroyed.'
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

  def new_membership_mailer
    NewMembershipMailer.with(membership: @membership).notify.deliver_later
  end

  def updated_membership_mailer
    UpdatedMembershipMailer.with(membership: @membership).notify.deliver_later
  end

  def cancelled_membership_mailer
    CancelledMembershipMailer.with(membership: @membership).notify.deliver_later
  end
end
