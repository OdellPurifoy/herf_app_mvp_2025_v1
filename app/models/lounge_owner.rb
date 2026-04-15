# frozen_string_literal: true

class LoungeOwner < ApplicationRecord
  NOT_SUBSCRIBED  = 'Default' ? Float::INFINITY : 0 # Include default devise modules. Others available are:
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

  def active_subscription
    subscriptions.active.first
  end

  # Legacy plan methods - kept for backward compatibility
  def robusto_plan?
    return false unless subscribed?

    active_subscription.name == 'robusto_monthly'
  end

  def churchill_plan?
    return false unless subscribed?

    active_subscription.name == 'churchill_monthly'
  end

  # Active plan methods
  def corona_plan?
    return false unless subscribed?

    active_subscription.name == 'corona_monthly'
  end

  def toro_plan?
    return false unless subscribed?

    active_subscription.name == 'toro_monthly'
  end

  def membership_limit
    return NOT_SUBSCRIBED unless subscribed?

    case active_subscription.name
    when 'robusto_monthly'
      50
    when 'churchill_monthly'
      150
    when 'corona_monthly'
      300
    when 'toro_monthly'
      Float::INFINITY
    else
      NOT_SUBSCRIBED
    end
  end

  def event_limit_per_month
    return NOT_SUBSCRIBED unless subscribed?

    case active_subscription.name
    when 'robusto_monthly'
      2
    when 'churchill_monthly'
      Float::INFINITY
    when 'corona_monthly'
      4
    when 'toro_monthly'
      Float::INFINITY
    else
      NOT_SUBSCRIBED
    end
  end

  def special_offer_limit_per_month
    return NOT_SUBSCRIBED unless subscribed?

    case active_subscription.name
    when 'robusto_monthly'
      2
    when 'churchill_monthly'
      Float::INFINITY
    when 'corona_monthly'
      2
    when 'toro_monthly'
      Float::INFINITY
    else
      NOT_SUBSCRIBED
    end
  end

  def reminders_enabled?
    churchill_plan? || corona_plan? || toro_plan?
  end

  private

  def date_of_birth_cannot_be_in_the_future
    return unless date_of_birth.present? && date_of_birth > Date.today

    errors.add(:date_of_birth, "Can't be in the future")
  end

  def must_be_18_or_older
    return unless date_of_birth.present? && date_of_birth > 18.years.ago

    errors.add(:date_of_birth, 'Must be 18 years or older')
  end
end
