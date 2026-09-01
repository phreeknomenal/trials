# "intersex" and "prefer not to say" are being removed from
# Profile::SEX_ASSIGNED_AT_BIRTH_OPTIONS. Rows still holding them would fail the
# inclusion validation on their next save, and the error would surface on a
# field the user may not even be editing.
#
# NULL is the correct landing spot rather than a substitute value. The scorer
# already treats an absent sex as unknown: neutral 50, no disqualifier. That is
# precisely the behaviour "prefer not to say" was meant to have and did not.
#
# Irreversible on purpose. The old values cannot be recovered, and inventing a
# sex to restore is worse than leaving the field blank.
class NullifyUnofferedSexAssignedAtBirthValues < ActiveRecord::Migration[8.1]
  REMOVED = ["intersex", "prefer not to say"].freeze

  def up
    execute <<~SQL.squish
      UPDATE profiles
      SET sex_assigned_at_birth = NULL
      WHERE sex_assigned_at_birth IN (#{REMOVED.map { |v| connection.quote(v) }.join(", ")})
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
