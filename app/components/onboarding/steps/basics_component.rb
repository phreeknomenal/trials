class Onboarding::Steps::BasicsComponent < Onboarding::Steps::BaseComponent
  def sex_options
    Profile::SEX_ASSIGNED_AT_BIRTH_ANSWERS.map { |sex| [option_label(sex), sex] }
  end
end
