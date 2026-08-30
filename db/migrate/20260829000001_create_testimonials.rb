class CreateTestimonials < ActiveRecord::Migration[8.1]
  def change
    create_table :testimonials do |t|
      t.text :quote, null: false
      t.string :author_name, null: false
      t.string :author_role
      t.integer :position, default: 0, null: false
      t.boolean :published, default: false, null: false
      # Marks seeded placeholder content so it can be removed in one command
      # once real, permissioned testimonials exist.
      t.boolean :placeholder, default: false, null: false

      t.timestamps

      t.index [:published, :position]
    end
  end
end
