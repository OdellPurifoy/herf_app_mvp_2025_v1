# frozen_string_literal: true

class EventRegistration < ApplicationRecord
  belongs_to :event

  enum :status, { registered: 0, cancelled: 1 }

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: 'must be a valid email address' }
  validates :number_of_guests, presence: true,
                               numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }
  validates :registration_token, presence: true, uniqueness: true
  validates :email, uniqueness: { scope: :event_id, message: 'is already registered for this event' }

  validate :event_must_be_upcoming, on: :create
  validate :capacity_not_exceeded, on: :create

  before_validation :generate_registration_token, on: :create

  scope :active, -> { where(status: :registered) }

  def full_name
    "#{first_name} #{last_name}"
  end

  def cancel!
    update!(status: :cancelled)
  end

  def self.find_by_token(token)
    find_by(registration_token: token)
  end

  def self.find_by_token!(token)
    find_by!(registration_token: token)
  end

  private

  def generate_registration_token
    self.registration_token ||= SecureRandom.uuid
  end

  def event_must_be_upcoming
    return if event.blank?

    return unless event.date.present? && event.date < Date.current

    errors.add(:event, 'has already occurred')
  end

  def capacity_not_exceeded
    return if event.blank?
    return if event.capacity.blank? # No cap set — unlimited

    total_member_attendees = event.total_confirmed_attendees
    total_public_registered = event.event_registrations.active.sum(:number_of_guests)
    spots_taken = total_member_attendees + total_public_registered
    spots_remaining = event.capacity - spots_taken

    return unless number_of_guests.present? && number_of_guests > spots_remaining

    if spots_remaining <= 0
      errors.add(:base, 'This event is at full capacity')
    else
      errors.add(:number_of_guests, "exceeds available spots (#{spots_remaining} remaining)")
    end
  end
end
