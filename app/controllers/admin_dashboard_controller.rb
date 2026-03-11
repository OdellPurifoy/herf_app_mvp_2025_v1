# frozen_string_literal: true

require 'csv'

class AdminDashboardController < ApplicationController
  # before_action :authenticate_admin!

  def index
    @total_lounge_owners = LoungeOwner.count
    @total_events = Event.count
    @total_rsvps = Rsvp.count
    @total_special_offers = SpecialOffer.count
  end

  def lounge_owners
    @lounge_owners = LoungeOwner.includes(:lounges).order(created_at: :desc)
  end

  def events
    @events = Event.includes(%i[lounge rsvps]).order(date: :desc)
  end

  def rsvps
    @rsvps = Rsvp.includes(event: :lounge, membership: []).order(created_at: :desc)
  end

  def special_offers
    @special_offers = SpecialOffer.includes(:lounge).order(created_at: :desc)
  end

  def member_upload
    # Check if file is present
    unless params[:members_file].present?
      flash[:alert] = 'Please select a CSV file to upload'
      redirect_to admin_path and return
    end

    # Validate file type
    content_type = params[:members_file].content_type
    filename = params[:members_file].original_filename

    unless content_type == 'text/csv' || filename.end_with?('.csv')
      flash[:alert] = 'Only CSV files are allowed'
      redirect_to admin_path and return
    end

    # Validate lounge selection
    unless params[:lounge_id].present? && Lounge.exists?(params[:lounge_id])
      flash[:alert] = 'Please select a valid lounge'
      redirect_to admin_path and return
    end

    # Process CSV safely
    begin
      csv_data = CSV.parse(params[:members_file].read, headers: true)

      csv_data.each do |row|
        first_name = row['First Name'].strip
        last_name = row['Last Name'].strip
        email = row['Email'].strip
        lounge_id = member_upload_params[:lounge_id]

        Membership.create!(first_name: first_name, last_name: last_name, email: email, lounge_id: lounge_id)
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error("Failed to create member: #{e.message}")
      end

      flash[:notice] = "Successfully uploaded #{csv_data.count} members"
      redirect_to admin_path
    rescue CSV::MalformedCSVError => e
      flash[:alert] = "Invalid CSV format: #{e.message}"
      redirect_to admin_path
    rescue StandardError => e
      flash[:alert] = "Error processing file: #{e.message}"
      redirect_to admin_path
    end
  end

  private

  def member_upload_params
    params.permit(:members_file, :lounge_id, :authenticity_token, :commit)
  end
end
