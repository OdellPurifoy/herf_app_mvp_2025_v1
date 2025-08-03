# frozen_string_literal: true

class CreateRsvps < ActiveRecord::Migration[7.1]
  def change
    create_table :rsvps, id: :uuid do |t|
      t.references :event, null: false, foreign_key: true, type: :uuid
      t.references :membership, null: false, foreign_key: true, type: :uuid
      t.integer :status, null: false, default: 0
      t.integer :guest_count, null: false, default: 1
      t.string :rsvp_token, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    # Add indexes for performance
    add_index :rsvps, :rsvp_token, unique: true
    add_index :rsvps, %i[event_id membership_id], unique: true
    add_index :rsvps, :expires_at
    add_index :rsvps, :status
  end
end
