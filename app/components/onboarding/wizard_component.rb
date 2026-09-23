# Chrome shared by every wizard step: progress, heading, the form wrapper, and
# the continue button. Steps render only their own fields.
class Onboarding::WizardComponent < ApplicationComponent
  attr_reader :profile, :step

  def initialize(profile:, step:)
    @profile = profile
    @step = step
  end

  # The community step lays out sixty one pills. At the column width every other
  # step uses that is far more rows than fit a screen, and the step has nothing
  # else on it to compete for the width.
  WIDE_STEPS = %w[community].freeze

  def column_class
    WIDE_STEPS.include?(step.slug) ? "max-w-3xl" : "max-w-xl"
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

  def skippable?
    !step.required?
  end

  def errors
    profile.errors.full_messages
  end
end
