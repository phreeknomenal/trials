# Plain-language eligibility questions for one study, written by Claude from
# the study's own criteria. One row per nct_id, shared by everyone who opens
# that study, the same as readable_study_summaries.
#
# criteria_digest is the criteria text the questions were written from. When a
# study team edits its criteria the digest stops matching, and the questions
# are rewritten rather than asking about a criterion the study dropped.
class CreateStudyPrescreens < ActiveRecord::Migration[8.1]
  def change
    create_table :study_prescreens do |t|
      t.string :nct_id, null: false
      t.string :status, null: false, default: "pending"
      t.jsonb :questions, null: false, default: []
      t.string :criteria_digest
      t.text :error_message
      t.datetime :generated_at

      t.timestamps
    end

    add_index :study_prescreens, :nct_id, unique: true
  end
end
