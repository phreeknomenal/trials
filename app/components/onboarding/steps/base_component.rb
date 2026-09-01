# Every step renders fields into the wizard's form. The chrome, progress, and
# submit button live in Onboarding::WizardComponent.
class Onboarding::Steps::BaseComponent < ApplicationComponent
  attr_reader :form, :profile

  def initialize(form:, profile:)
    @form = form
    @profile = profile
  end
end
