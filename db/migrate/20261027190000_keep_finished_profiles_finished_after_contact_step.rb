# The wizard gained a ninth step, contact, so finishing it now means reaching
# 10. A profile that had already finished all eight steps holds 9, which would
# read as "the contact step is next" and pull its owner back into the wizard
# with the finish-your-profile nudge. Those profiles stay finished; contact
# details can still be filled in from the profile page.
class KeepFinishedProfilesFinishedAfterContactStep < ActiveRecord::Migration[8.1]
  # Literals rather than Onboarding.complete_number, so this migration keeps its
  # meaning when steps are added later.
  FINISHED_BEFORE = 9
  FINISHED_AFTER = 10

  def up
    execute "UPDATE profiles SET onboarding_step = #{FINISHED_AFTER} WHERE onboarding_step >= #{FINISHED_BEFORE}"
  end

  def down
    execute "UPDATE profiles SET onboarding_step = #{FINISHED_BEFORE} WHERE onboarding_step >= #{FINISHED_AFTER}"
  end
end
