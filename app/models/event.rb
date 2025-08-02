# frozen_string_literal: true

class Event < ApplicationRecord
  TYPES = ['Holiday Party', 'Live Music', 'Wine Tasting', 'Whiskey Tasting', 'Beer Tasting', 'Cigar Brand Event',
           'Birthday Party', 'Corporate Event', 'Sporting Event', 'Other'].freeze

  belongs_to :lounge
  has_many :rsvps, dependent: :destroy

  has_one_attached :flyer

  validates :name, :event_type, :date, :start_time, :end_time, presence: true
  validate :end_time_after_start_time
  validate :date_not_in_past

  scope :upcoming, -> { where('date >= ?', Date.today).order(date: :asc, start_time: :asc) }

  after_create :notify_members_of_creation
  after_update :notify_members_of_update
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

  def not_attending_rsvps_count
    rsvps.not_attending.count
  end

  def create_rsvps_for_members!
    return unless rsvp_needed?

    lounge.memberships.active.find_each do |membership|
      rsvps.create_for_event_and_membership(self, membership)
    end
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

  private

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
