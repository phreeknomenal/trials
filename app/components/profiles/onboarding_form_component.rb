class Profiles::OnboardingFormComponent < ApplicationComponent
  def initialize(profile:)
    @profile = profile
  end

  private

  attr_reader :profile
end
