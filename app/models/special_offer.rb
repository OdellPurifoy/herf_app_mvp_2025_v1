# frozen_string_literal: true

class SpecialOffer < ApplicationRecord
  TYPES = ['BOGO', 'Half Off', 'Brand Discount', 'Holiday Discount', 'Other'].freeze

  belongs_to :lounge

  validates :name, :offer_type, :start_date, :end_date, presence: true
  validate :end_date_after_start_date

  has_one_attached :flyer

  scope :upcoming, -> { where('end_date >= ?', Date.today).order(end_date: :asc) }

  after_create :notify_members_of_creation
  after_update :notify_members_of_update
  after_destroy :notify_members_of_deletion

  paginates_per 5

  def self.ransackable_attributes(_auth_object = nil)
    %w[name offer_type start_date end_date members_only offer_code description]
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    return unless end_date.before?(start_date)

    errors.add(:end_date, 'must be after the start date')
  end

  def notify_members_of_creation
    SpecialOfferCreationNotificationJob.perform_later(id)
  end

  def notify_members_of_update
    SpecialOfferUpdateNotificationJob.perform_later(id)
  end

  def notify_members_of_deletion
    special_offer_data = {
      id: id,
      name: name,
      start_date: start_date,
      end_date: end_date,
      member_ids: lounge.memberships.active.pluck(:id)
    }
    SpecialOfferDeletionNotificationJob.perform_later(special_offer_data)
  end
end
