class CreateProfileInterests < ActiveRecord::Migration[8.0]
  def change
    create_table :profile_interests do |t|
      t.references :profile, null: false, foreign_key: true
      t.references :interest, null: false, foreign_key: true

      t.timestamps
    end

    add_index :profile_interests, [ :profile_id, :interest_id ], unique: true
  end
end
