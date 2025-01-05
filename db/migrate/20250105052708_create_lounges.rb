class CreateLounges < ActiveRecord::Migration[7.1]
  def change
    create_table :lounges, id: :uuid do |t|
      t.string :name, null: false
      t.string :address_street_1, null: false
      t.string :address_street_2
      t.string :city, null: false
      t.string :state, null: false
      t.string :zip_code, null: false
      t.string :phone_number
      t.string :email, null: false
      t.text   :description
      t.string :facebook_handle
      t.string :x_handle
      t.string :instagram_handle
      t.boolean :outside_cigars_allowed, default: false
      t.boolean :outside_food_allowed, default: false
      t.boolean :alcohol_served, default: false
      t.boolean :outside_alcohol_allowed, default: false
      t.boolean :food_served, default: false
      t.string :website
      t.references :lounge_owner, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
