# frozen_string_literal: true

class CreateMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :memberships, id: :uuid do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email
      t.string :phone_number
      t.boolean :opt_out_text_messaging, default: false
      t.boolean :allow_text_notifications, default: true
      t.boolean :allow_email_notifications, default: true
      t.references :lounge, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
