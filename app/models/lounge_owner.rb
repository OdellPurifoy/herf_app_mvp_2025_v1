# frozen_string_literal: true

class LoungeOwner < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable

  has_person_name
  pay_customer default_payment_processor: :stripe

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :first_name, :last_name, presence: true
  validates :date_of_birth, presence: true,
                            format: { with: /\d{4}-\d{2}-\d{2}/, message: 'must be in the format YYYY-MM-DD' }
  validate  :date_of_birth_cannot_be_in_the_future
  validate  :must_be_18_or_older

  has_many :lounges, dependent: :destroy

  def full_name
    "#{first_name} #{last_name}"
  end

  # Subscription-related methods
  def subscribed?
    subscriptions.active.any?
  end

  def can_create_lounge?
    subscribed?
  end

  def subscription_name
    return nil unless subscribed?

    subscription = subscriptions.active.first
    subscription.name.capitalize
  end

  private

  def date_of_birth_cannot_be_in_the_future
    return unless date_of_birth.present? && date_of_birth > Date.today

    errors.add(:date_of_birth, "can't be in the future")
  end

  def must_be_18_or_older
    return unless date_of_birth.present? && date_of_birth > 18.years.ago

    errors.add(:date_of_birth, 'must be 18 years or older')
  end
end
