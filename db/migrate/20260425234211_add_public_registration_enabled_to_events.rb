# frozen_string_literal: true

class AddPublicRegistrationEnabledToEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :public_registrations_enabled, :boolean, default: false, null: false
  end
end
