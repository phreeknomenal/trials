# Tracks how far through the wizard a profile has reached.
#
# Deriving the step from which fields are filled looks tempting and breaks as
# soon as a step is optional: a skipped step stays unfilled forever and would
# trap its owner there. Progress is its own fact.
class AddOnboardingStepToProfiles < ActiveRecord::Migration[8.1]
  # Onboarding::STEPS has four entries today, so 5 means "past all of them".
  # Written as a literal rather than read from the constant, because a later
  # migration must not change meaning when steps are added.
  COMPLETED = 5

  def up
    add_column :profiles, :onboarding_step, :integer, null: false, default: 1

    # Anyone already onboarded finished under the old single-form modal and must
    # not be dropped back into the wizard.
    execute "UPDATE profiles SET onboarding_step = #{COMPLETED} WHERE onboarded = true"
  end

  def down
    remove_column :profiles, :onboarding_step
  end
end
