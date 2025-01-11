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

  private

  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?

    return unless end_time < start_time

    errors.add(:end_time, 'must be after the start time')
  end

  def date_not_in_past
    return if date.blank?

    return unless date < Date.today

    errors.add(:date, 'must be in the future')
  end
end
