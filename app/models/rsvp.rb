# frozen_string_literal: true

class Rsvp < ApplicationRecord
  belongs_to :event
  belongs_to :membership

  # Enum for RSVP status - using integer for performance
  enum status: {
    pending: 0,
    attending: 1,
    declined: 2, # Changed from not_attending
    expired: 3
  }

  # Validations
  validates :guest_count, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 10 }
  validates :rsvp_token, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validates :event_id, uniqueness: { scope: :membership_id, message: 'can only have one RSVP per event' }

  # Scopes
  scope :valid, -> { where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  scope :for_upcoming_events, -> { joins(:event).where('events.event_date > ?', Time.current) }

  # Callbacks
  before_validation :generate_rsvp_token, on: :create
  before_validation :set_expiration_date, on: :create
  after_update :mark_expired_if_past_due

  class << self
    def find_by_token(token)
      find_by(rsvp_token: token)
    end

    def create_for_event_and_membership(event, membership, guest_count: 1)
      create!(
        event: event,
        membership: membership,
        guest_count: guest_count,
        status: :pending
        # expiration and token will be set by callbacks
      )
    end
  end

  def expired?
    expires_at <= Time.current
  end

  def valid_for_response?
    !expired? && pending?
  end

  def respond_with(status_value, guest_count_value = nil)
    return false if expired?

    update(
      status: status_value,
      guest_count: guest_count_value || guest_count
    )
  end

  def total_attendees
    attending? ? guest_count : 0
  end

  # For display purposes
  def status_display
    case status
    when 'pending'
      'Awaiting Response'
    when 'attending'
      "Attending (#{guest_count} #{'guest'.pluralize(guest_count)})"
    when 'declined'
      'Not Attending'
    when 'expired'
      'Expired'
    end
  end

  def member_name
    membership.member_name
  end

  def event_title
    event.name
  end

  private

  def generate_rsvp_token
    self.rsvp_token = SecureRandom.urlsafe_base64(32) if rsvp_token.blank?
  end

  def set_expiration_date
    # RSVPs expire 1 hour before the event starts
    self.expires_at = event.event_date - 1.hour if expires_at.blank? && event.present?
  end

  def mark_expired_if_past_due
    update_column(:status, :expired) if expired? && !expired?
  end
end
