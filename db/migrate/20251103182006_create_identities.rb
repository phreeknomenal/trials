class CreateIdentities < ActiveRecord::Migration[8.0]
  def change
    create_table :identities do |t|
      t.text :name, null: false, index: { unique: true }

      t.timestamps
    end
  end
end
