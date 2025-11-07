class Profiles::OnboardingModalComponent < ApplicationComponent
  def initialize(profile:)
    @profile = profile
  end

  def render?
    @profile.present? && !@profile.profile_completed?
  end

  private

  attr_reader :profile
end
