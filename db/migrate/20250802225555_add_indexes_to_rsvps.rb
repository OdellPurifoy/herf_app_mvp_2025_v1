# frozen_string_literal: true

class AddIndexesToRsvps < ActiveRecord::Migration[7.1]
  def change
    # Add missing indexes for performance and constraints (only if they don't exist)
    add_index :rsvps, :rsvp_token, unique: true unless index_exists?(:rsvps, :rsvp_token)
    unless index_exists?(
      :rsvps, %i[event_id membership_id]
    )
      add_index :rsvps, %i[event_id membership_id], unique: true,
                                                    name: 'index_rsvps_on_event_id_and_membership_id'
    end
    add_index :rsvps, :expires_at unless index_exists?(:rsvps, :expires_at)
    add_index :rsvps, :status unless index_exists?(:rsvps, :status)

    # Add constraints (these should be safe to run multiple times)
    change_column_null :rsvps, :status, false
    change_column_null :rsvps, :guest_count, false
    change_column_null :rsvps, :rsvp_token, false
    change_column_null :rsvps, :expires_at, false

    # Add default values
    change_column_default :rsvps, :status, 0
    change_column_default :rsvps, :guest_count, 1
  end
end
