class Onboarding::Steps::AboutYouComponent < Onboarding::Steps::BaseComponent
  def pronoun_options
    Profile::PRONOUN_OPTIONS.map { |option| [option.titleize, option] }
  end

  def ethnicity_options
    Profile::ETHNICITY_OPTIONS.map { |option| [option.titleize, option] }
  end
end
