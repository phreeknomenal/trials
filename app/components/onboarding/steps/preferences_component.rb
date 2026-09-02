class Onboarding::Steps::PreferencesComponent < Onboarding::Steps::BaseComponent
  def trial_type_options
    Profile::TRIAL_TYPE_PREFERENCE_OPTIONS.map { |option| [option.titleize, option] }
  end

  # Spelled out rather than titleized. "Approved Treatments Only" tells someone
  # nothing about what they are agreeing to; the phase each one implies does.
  RISK_DESCRIPTIONS = {
    Profile::APPROVED_ONLY => "Approved treatments only (Phase 4)",
    Profile::TESTED => "Already tested in other patients (Phase 2 and later)",
    Profile::EARLY_STAGE_OKAY => "I am open to early-stage studies (any phase)"
  }.freeze

  def risk_options
    Profile::RISK_TOLERANCE_OPTIONS.map { |option| [RISK_DESCRIPTIONS.fetch(option, option.titleize), option] }
  end
end
