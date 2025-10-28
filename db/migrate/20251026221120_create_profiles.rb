class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :race, null: true, foreign_key: true
      t.references :gender, null: true, foreign_key: true

      t.string :first_name
      t.string :last_name
      t.date :birth_date
      t.string :zip_code
      t.string :phone_number
      t.string :pronouns
      t.boolean :onboarded, default: false, null: false

      t.timestamps
    end
  end
end
