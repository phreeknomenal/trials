class CreateProfileConditions < ActiveRecord::Migration[8.0]
  def change
    create_table :profile_conditions do |t|
      t.references :profile, null: false, foreign_key: true
      t.references :condition, null: false, foreign_key: true
      t.boolean :is_primary, default: false

      t.timestamps
    end

    add_index :profile_conditions, [:profile_id, :condition_id], unique: true
  end
end
