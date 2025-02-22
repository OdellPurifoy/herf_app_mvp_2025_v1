# frozen_string_literal: true

class Membership < ApplicationRecord
  belongs_to :lounge

  validates :first_name, :last_name, presence: true

  paginates_per 5
end
