# Every step renders fields into the wizard's form. The chrome, progress, and
# submit button live in Onboarding::WizardComponent.
class Onboarding::Steps::BaseComponent < ApplicationComponent
  attr_reader :form, :profile

  def initialize(form:, profile:)
    @form = form
    @profile = profile
  end

  # Titleized, the declines read "Prefer Not To Say", which looks like a
  # heading rather than an answer.
  DECLINE_LABELS = {
    Profile::PREFER_NOT_TO_SAY => "Prefer not to say",
    Profile::NO_PREFERENCE => "No preference"
  }.freeze

  def option_label(value) = DECLINE_LABELS.fetch(value) { value.titleize }

  # The blank option means "not answered yet". Declining is one of the real
  # options, so the two can no longer be confused once saved.
  UNANSWERED_PROMPT = "Choose one"
end
