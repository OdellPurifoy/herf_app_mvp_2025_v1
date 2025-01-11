class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events, id: :uuid do |t|
      t.string :name, null: false
      t.string :event_type, null: false
      t.date :date, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.boolean :virtual, default: false
      t.boolean :members_only, default: false
      t.text :description
      t.boolean :rsvp_needed, default: false
      t.integer :capacity
      t.string :entry_fee
      t.references :lounge, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
