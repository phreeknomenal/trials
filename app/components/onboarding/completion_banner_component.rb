# The finish-your-profile nudge, shown once the required steps are done but
# optional ones remain. A suggestion rather than a task, so it is dismissible
# and dismissal is remembered per device.
class Onboarding::CompletionBannerComponent < ApplicationComponent
  def initialize(profile:, dismissed: false)
    @profile = profile
    @dismissed = dismissed
  end

  def render?
    return false if @profile.blank? || @dismissed
    return false unless @profile.onboarding_unlocked?

    !@profile.profile_completed?
  end

  def next_step
    @profile.current_onboarding_step
  end

  def remaining
    Onboarding.count - @profile.onboarding_progress + 1
  end
end
