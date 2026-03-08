class CreateSavedTrials < ActiveRecord::Migration[8.1]
  def change
    create_table :saved_trials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :nct_id, null: false
      t.string :trial_title
      t.string :tags
      t.string :status, default: "interested", null: false
      t.decimal :match_score, precision: 5, scale: 2

      t.string :phase
      t.string :study_type
      t.string :trial_status
      t.integer :min_age
      t.integer :max_age
      t.integer :enrollment_count
      t.date :start_date
      t.date :completion_date
      t.string :sponsor
      t.text :summary

      t.timestamps
    end

    add_index :saved_trials, [ :user_id, :nct_id ], unique: true, name: "index_saved_trials_on_user_and_nct"
    add_index :saved_trials, :status
    add_index :saved_trials, :created_at
  end
end
