# frozen_string_literal: true

class Membership < ApplicationRecord
  has_person_name

  belongs_to :lounge
  has_many :rsvps, dependent: :destroy

  validates :first_name, :last_name, presence: true

  paginates_per 5

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[first_name last_name email phone_number opt_out_text_messaging allow_text_notifications
       allow_email_notifications]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[lounge rsvps]
  end

  def member_name
    "#{first_name} #{last_name}"
  end

  def rsvp_for_event(event)
    rsvps.find_by(event: event)
  end

  def pending_rsvps
    rsvps.pending.joins(:event).where('events.date >= ?', Date.current)
  end

  def upcoming_events_attending
    rsvps.attending.joins(:event).where('events.date >= ?', Date.current)
  end
end
