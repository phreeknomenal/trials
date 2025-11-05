class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :race, null: true, foreign_key: true
      t.references :gender, null: true, foreign_key: true

      t.string :first_name
      t.string :last_name
      t.integer :birth_year
      t.string :pronouns
      t.string :sex_assigned_at_birth
      t.string :ethnicity, default: "prefer not to say"

      t.string :city
      t.string :state
      t.string :country, default: "US"
      t.string :zip_code
      t.string :phone_number

      t.string :primary_condition
      t.string :condition_subtype
      t.string :diagnosis_timing
      t.string :current_treatment
      t.boolean :prior_treatment, default: false

      t.integer :willing_travel_miles
      t.boolean :transportation_reliable, default: true
      t.string :remote_visit_preference
      t.string :trial_type_preference
      t.string :risk_tolerance
      t.string :contact_preference
      t.string :language_preference

      t.boolean :onboarded, default: false, null: false

      t.timestamps
    end
  end
end
