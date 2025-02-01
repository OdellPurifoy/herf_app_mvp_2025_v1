# frozen_string_literal: true

class Lounge < ApplicationRecord
  belongs_to :lounge_owner

  validates :name, :address_street_1, :city, :state, :zip_code, :email, presence: true

  has_one_attached :logo
  has_one_attached :cover_image
  has_many :events, dependent: :destroy
  has_many :special_offers, dependent: :destroy
  has_many :memberships, dependent: :destroy
end
