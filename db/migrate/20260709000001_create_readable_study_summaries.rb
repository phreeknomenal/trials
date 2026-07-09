class CreateReadableStudySummaries < ActiveRecord::Migration[8.1]
  def change
    create_table :readable_study_summaries do |t|
      t.string :nct_id, null: false
      t.text :content
      t.string :status, default: "pending", null: false
      t.text :error_message
      t.datetime :generated_at

      t.timestamps
    end

    add_index :readable_study_summaries, :nct_id, unique: true
  end
end
