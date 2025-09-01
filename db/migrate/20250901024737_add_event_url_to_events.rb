# frozen_string_literal: true

class AddEventUrlToEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :virtual_url, :string
    add_column :events, :virtual_passcode, :string
  end
end
