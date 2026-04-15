# frozen_string_literal: true

class Event < ApplicationRecord
  TYPES = ['Holiday Party', 'Live Music', 'Wine Tasting', 'Whiskey Tasting', 'Beer Tasting', 'Cigar Brand Event',
           'Birthday Party', 'Corporate Event', 'Sporting Event', 'Other'].freeze

  belongs_to :lounge
  has_many :rsvps, dependent: :destroy

  has_one_attached :flyer

  validates :name, :event_type, :date, :start_time, :end_time, presence: true
  validates :virtual_url, presence: true, if: -> { virtual? }
  validate :end_time_after_start_time
  validate :date_not_in_past
  validate :event_limit_not_exceeded

  scope :upcoming, -> { where('date >= ?', Date.today).order(date: :asc, start_time: :asc) }

  after_create :notify_members_of_creation
  after_create :create_rsvps_if_needed
  after_update :notify_members_of_update
  after_update :create_rsvps_if_rsvp_enabled
  after_destroy :notify_members_of_deletion

  paginates_per 5

  def self.ransackable_attributes(_auth_object = nil)
    %w[name event_type date start_time end_time description virtual members_only rsvp_needed capacity entry_fee]
  end

  def event_date
    # Combine date and start_time for a full datetime
    return nil if date.blank? || start_time.blank?

    DateTime.new(date.year, date.month, date.day, start_time.hour, start_time.min, start_time.sec)
  end

  def total_confirmed_attendees
    rsvps.attending.sum(:guest_count)
  end

  def pending_rsvps_count
    rsvps.pending.count
  end

  def attending_rsvps_count
    rsvps.attending.count
  end

  def declined_rsvps_count
    rsvps.declined.count
  end

  def create_rsvps_for_members!
    return unless rsvp_needed?
    return if rsvps.exists? # Don't create duplicates

    ActiveRecord::Base.transaction do
      lounge.memberships.active.find_each do |membership|
        rsvps.create!(
          membership: membership,
          status: :pending,
          guest_count: 1,
          expires_at: event_date - 1.hour
        )
      end
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create RSVPs for event #{id}: #{e.message}"
    false
  end

  def rsvp_for_membership(membership)
    rsvps.find_by(membership: membership)
  end

  def capacity_remaining
    return nil unless capacity.present?

    capacity - total_confirmed_attendees
  end

  def at_capacity?
    return false unless capacity.present?

    total_confirmed_attendees >= capacity
  end

  def rsvp_summary
    return nil unless rsvp_needed?

    {
      total_invites: rsvps.count,
      pending: pending_rsvps_count,
      attending: attending_rsvps_count,
      declined: declined_rsvps_count,
      total_guests: total_confirmed_attendees,
      capacity_remaining: capacity_remaining
    }
  end

  def rsvp_response_rate
    return 0 unless rsvp_needed? && rsvps.count.positive?

    responded = attending_rsvps_count + declined_rsvps_count
    (responded.to_f / rsvps.count * 100).round(1)
  end

  private

  def create_rsvps_if_needed
    create_rsvps_for_members! if rsvp_needed?
  end

  def create_rsvps_if_rsvp_enabled
    # Only create RSVPs if RSVP was just enabled and we don't have any RSVPs yet
    return unless saved_change_to_rsvp_needed? && rsvp_needed? && rsvps.empty?

    create_rsvps_for_members!
  end

  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?

    return unless end_time.before? start_time

    errors.add(:end_time, 'must be after the start time')
  end

  def date_not_in_past
    return if date.blank?

    return unless date.before? Date.today

    errors.add(:date, 'must be in the future')
  end

  def event_limit_not_exceeded
    return unless new_record? # Only validate on create
    return unless lounge&.lounge_owner&.subscribed?
    return if date.blank?

    lounge_owner = lounge.lounge_owner
    limit = lounge_owner.event_limit_per_month

    # Churchill and Toro plans have unlimited events
    return if limit == Float::INFINITY

    # Count events in the same month as the new event
    start_of_month = date.beginning_of_month
    end_of_month = date.end_of_month
    events_this_month = lounge.events.where(date: start_of_month..end_of_month).count

    return if events_this_month < limit || lounge_owner.subscription_name == 'Default'

    # Get the plan name dynamically
    plan_name = lounge_owner.subscription_name || 'your current'
    errors.add(:base,
               "Event limit reached. Your #{plan_name} plan allows up to #{limit.to_i} events per month. Please upgrade to create more events.")
  end

  def notify_members_of_creation
    EventCreationNotificationJob.perform_later(id)
  end

  def notify_members_of_update
    EventUpdateNotificationJob.perform_later(id)
  end

  def notify_members_of_deletion
    event_data = {
      id: id,
      name: name,
      date: date,
      member_ids: lounge.memberships.active.pluck(:id) # Assuming you have a members association
    }
    EventDeletionNotificationJob.perform_later(event_data)
  end
end
