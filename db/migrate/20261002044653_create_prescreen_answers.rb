# A signed-in person's answer to one pre-screen question. Self-reported health
# information, so it is listed on the privacy page and goes with the account.
#
# Keyed by nct_id and question_key rather than a foreign key to the prescreen
# row. Rewritten questions get new keys, which leaves old answers unmatched
# instead of deleting them, so a study that reverts its criteria finds them.
class CreatePrescreenAnswers < ActiveRecord::Migration[8.1]
  def change
    create_table :prescreen_answers do |t|
      t.references :user, null: false, foreign_key: true
      t.string :nct_id, null: false
      t.string :question_key, null: false
      t.string :answer, null: false

      t.timestamps
    end

    add_index :prescreen_answers, [:user_id, :nct_id, :question_key], unique: true,
      name: "index_prescreen_answers_on_user_study_question"
  end
end
