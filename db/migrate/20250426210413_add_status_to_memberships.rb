# frozen_string_literal: true

class AddStatusToMemberships < ActiveRecord::Migration[7.1]
  def change
    add_column :memberships, :active, :boolean, default: true
  end
end
