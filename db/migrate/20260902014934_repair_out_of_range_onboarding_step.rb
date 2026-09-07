# A profile whose onboarding_step fell below 1 crashed the onboarding gate on
# every page, because current_onboarding_step returned nil and the gate called
# .slug on it. The clamp in Profile#onboarding_progress stops that crashing, and
# this repairs the rows plus closes the hole that let them in.
#
# ActiveRecord casts a non-numeric assignment to 0 rather than rejecting it, so
# "abc" silently becomes a valid-looking integer. The model now validates the
# lower bound; the check constraint is what makes it true regardless of how a
# row is written, including update_column and raw SQL, both of which skip
# validations and are how the wizard advances progress.
class RepairOutOfRangeOnboardingStep < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE profiles SET onboarding_step = 1 WHERE onboarding_step < 1"

    add_check_constraint :profiles, "onboarding_step >= 1", name: "profiles_onboarding_step_positive"
  end

  def down
    remove_check_constraint :profiles, name: "profiles_onboarding_step_positive"
  end
end
