class CreateProfileIdentities < ActiveRecord::Migration[8.0]
  def change
    create_table :profile_identities do |t|
      t.references :profile, null: false, foreign_key: true
      t.references :identity, null: false, foreign_key: true

      t.timestamps
    end

    add_index :profile_identities, [:profile_id, :identity_id], unique: true
  end
end
