# frozen_string_literal: true

class DropMembersOnlyFromEvents < ActiveRecord::Migration[7.1]
  def change
    remove_column :events, :members_only, :boolean, default: false, null: false
  end
end
