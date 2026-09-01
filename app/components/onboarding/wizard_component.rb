# Chrome shared by every wizard step: progress, heading, the form wrapper, and
# the continue button. Steps render only their own fields.
class Onboarding::WizardComponent < ApplicationComponent
  attr_reader :profile, :step

  def initialize(profile:, step:)
    @profile = profile
    @step = step
  end

  def total
    Onboarding.count
  end

  def percent_complete
    ((step.number - 1).to_f / total * 100).round
  end

  def previous_step
    Onboarding.at(step.number - 1)
  end

  def last_step?
    step.number == total
  end

  def button_label
    last_step? ? "Finish" : "Continue"
  end

  def errors
    profile.errors.full_messages
  end
end
