# frozen_string_literal: true

class CreateSpecialOffers < ActiveRecord::Migration[7.1]
  def change
    create_table :special_offers, id: :uuid do |t|
      t.string :name, null: false
      t.string :offer_type, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.boolean :members_only, default: false
      t.string :offer_code
      t.text :description
      t.references :lounge, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
