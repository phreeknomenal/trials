class Onboarding::Steps::IdentityComponent < Onboarding::Steps::BaseComponent
  # Moved here with the field itself. Pronouns are how to address someone, which
  # is what this step asks, rather than a demographic for reporting.
  def pronoun_options
    Profile::PRONOUN_OPTIONS.map { |option| [option.titleize, option] }
  end
end
