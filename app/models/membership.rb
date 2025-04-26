# frozen_string_literal: true

class Membership < ApplicationRecord
  belongs_to :lounge

  validates :first_name, :last_name, presence: true

  paginates_per 5

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[first_name last_name email phone_number opt_out_text_messaging allow_text_notifications
       allow_email_notifications]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[lounge]
  end
end
