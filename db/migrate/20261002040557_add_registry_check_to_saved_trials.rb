# A saved trial was a snapshot that never looked at the registry again, so a
# study could stop recruiting and My Trials kept saying it was recruiting.
#
# Two halves. registry_* is what the registry said at the last check.
# seen_last_update, with the existing trial_status, is what the person last
# saw. A badge is the difference between them.
#
# No backfill. seen_last_update fills on each row's first check, which is the
# only point the registry date is known, and trial_status already holds a real
# baseline from save time.
class AddRegistryCheckToSavedTrials < ActiveRecord::Migration[8.1]
  def change
    change_table :saved_trials, bulk: true do |t|
      t.string :registry_status
      t.date :registry_last_update
      t.text :registry_why_stopped
      t.datetime :registry_checked_at
      t.date :seen_last_update
    end
  end
end
