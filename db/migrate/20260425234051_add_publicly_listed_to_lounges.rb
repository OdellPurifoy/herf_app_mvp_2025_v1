# frozen_string_literal: true

class AddPubliclyListedToLounges < ActiveRecord::Migration[7.1]
  def change
    add_column :lounges, :publicly_listed, :boolean, default: false, null: false
  end
end
