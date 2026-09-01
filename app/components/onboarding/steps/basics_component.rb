class Onboarding::Steps::BasicsComponent < Onboarding::Steps::BaseComponent
  def sex_options
    Profile::SEX_ASSIGNED_AT_BIRTH_OPTIONS.map { |sex| [sex.titleize, sex] }
  end
end
