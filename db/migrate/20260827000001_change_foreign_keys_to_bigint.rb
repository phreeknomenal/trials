# Every primary key in this schema is bigint, but these foreign keys were
# declared with t.integer, so they were int4 pointing at int8. SQLite masked it
# entirely -- its INTEGER is 64-bit regardless of declaration -- and Postgres
# permits the mismatched constraint, so nothing was visibly broken. It is still
# a ceiling at ~2.1 billion and a needless type conversion on every join.
#
# ALTER COLUMN TYPE takes an ACCESS EXCLUSIVE lock and rewrites the table. These
# tables are small, so this is fast, but it is worth knowing since it runs in
# Heroku's release phase.
class ChangeForeignKeysToBigint < ActiveRecord::Migration[8.1]
  COLUMNS = {
    profiles: [:user_id, :gender_id, :race_id],
    saved_trials: [:user_id],
    profile_conditions: [:profile_id, :condition_id],
    profile_identities: [:profile_id, :identity_id],
    profile_interests: [:profile_id, :interest_id]
  }.freeze

  def up
    COLUMNS.each { |table, cols| cols.each { |col| change_column table, col, :bigint } }
  end

  def down
    COLUMNS.each { |table, cols| cols.each { |col| change_column table, col, :integer } }
  end
end
