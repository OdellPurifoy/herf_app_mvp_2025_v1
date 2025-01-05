class Lounge < ApplicationRecord
  belongs_to :lounge_owner

  validates :name, :address_street_1, :city, :state, :zip_code, :email, presence: true
end
