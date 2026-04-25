# frozen_string_literal: true

class CreateEventRegistrations < ActiveRecord::Migration[7.1]
  def change
    create_table :event_registrations, id: :uuid do |t|
      t.references :event, null: false, foreign_key: true, type: :uuid
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :phone_number
      t.integer :number_of_guests, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.uuid :registration_token, null: false
      t.boolean :opt_in_to_membership, default: false, null: false

      t.timestamps
    end

    add_index :event_registrations, :registration_token, unique: true
    add_index :event_registrations, %i[event_id email], unique: true,
                                                        name: 'index_event_registrations_on_event_id_and_email'
  end
end
