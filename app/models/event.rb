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

  after_create :send_new_event_notifications
  after_update :send_updated_event_notifications

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

  def send_new_event_notifications
    EventNotificationService.new(self, new_event_message).notify_members
  end

  def send_updated_event_notifications
    EventNotificationService.new(self, updated_event_message).notify_members
  end

  def new_event_message
    message = "#{lounge.name} is hosting an event: #{name} on #{date.strftime('%m/%d/%Y')} "
    message += "from #{start_time.strftime('%I:%M %p')} to #{end_time.strftime('%I:%M %p')}. "
    message += description.to_s if description.present?
    message += " Capacity: #{capacity}." if capacity.present?
    message += " Entry fee: $#{'%.2f' % entry_fee}." if entry_fee.present? && entry_fee.to_f > 0
    message += ' This is a members-only event.' if members_only?
    message += ' RSVP required.' if rsvp_needed?
    message
  end

  def updated_event_message
    message = "#{name} has updated the event: #{name} on #{date.strftime('%m/%d/%Y')}. "
    if saved_changes.any?
      changes = saved_changes.except(:updated_at).map do |attr, values|
        old_value, new_value = values
        "#{attr.humanize}: '#{old_value}' → '#{new_value}'"
      end
      message += "Changes: #{changes.join(', ')}."
    end
    message
  end
end
