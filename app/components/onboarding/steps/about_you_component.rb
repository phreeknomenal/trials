class Onboarding::Steps::AboutYouComponent < Onboarding::Steps::BaseComponent
  def ethnicity_options
    Profile::ETHNICITY_OPTIONS.map { |option| [option.titleize, option] }
  end
end
