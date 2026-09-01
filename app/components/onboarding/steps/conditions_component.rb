class Onboarding::Steps::ConditionsComponent < Onboarding::Steps::BaseComponent
  # The wizard renders a blank row so the step is usable without first clicking
  # "add". Only build one when the profile has none, or a returning user would
  # collect an empty row on every visit.
  def before_render
    profile.profile_conditions.build if profile.profile_conditions.empty?
  end
end
