# frozen_string_literal: true

class Event < ApplicationRecord
  TYPES = ['Holiday Party', 'Live Music', 'Wine Tasting', 'Whiskey Tasting', 'Beer Tasting', 'Cigar Brand Event',
           'Birthday Party', 'Corporate Event', 'Sporting Event', 'Other'].freeze

  belongs_to :lounge

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
    EventCreationNotificationJob.perform_later(id, :create)
  end

  def notify_members_of_update
    EventUpdateNotificationJob.perform_later(id)
  end

  def notify_members_of_deletion
    event_data = {
      id: id,
      name: name,
      date: date,
      member_ids: lounge.members.active.pluck(:id) # Assuming you have a members association
    }
    EventDeletionNotificationJob.perform_later(event_data)
  end
end
