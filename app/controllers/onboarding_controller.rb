# The profile wizard. One step per URL, each persisted on submit.
#
# This replaced a single modal rendered from the application layout that
# submitted every field at once. That form could not be resumed, lost
# everything on abandon, and blocked the app with a CSS overlay while
# ApplicationController#ensure_profile_completed was an empty stub.
class OnboardingController < ApplicationController
  # No navigation chrome. The wizard is the only thing on screen.
  layout "onboarding"

  # The gate redirects here, so this controller cannot be subject to it.
  skip_before_action :ensure_profile_completed

  before_action :authenticate_user!
  before_action :set_profile
  before_action :redirect_completed_wizard, except: :dismiss_banner
  before_action :set_step, except: :dismiss_banner

  def show
  end

  def update
    @profile.assign_attributes(step_params)

    if @profile.save(context: @step.context)
      advance_past(@step)
      redirect_to destination_after(@step)
    else
      render :show, status: :unprocessable_entity
    end
  end

  # Optional steps can be passed over. Skipping advances progress exactly like a
  # submit, because progress is the source of truth: leaving the step unfilled
  # and inferring "not done" would nag the user about it forever.
  def skip
    return redirect_to onboarding_step_path(step: @step.slug) if @step.required?

    advance_past(@step)
    redirect_to destination_after(@step)
  end

  # The finish-your-profile nudge is a suggestion, not a task. Dismissal lives in
  # a cookie rather than on the profile: it is a per-device display preference,
  # not something about the person.
  def dismiss_banner
    cookies.permanent[:onboarding_banner_dismissed] = "1"

    redirect_back fallback_location: root_path
  end

  private

  def set_profile
    @profile = current_user.profile
    # User#add_default_profile builds one at signup, so this should not happen.
    # If it ever does, the profile controller is the honest place to recover.
    redirect_to new_profile_path if @profile.nil?
  end

  def redirect_completed_wizard
    redirect_to root_path if @profile&.profile_completed?
  end

  # Forward jumps are refused so a required step cannot be stepped over by URL.
  # Going back to an already-completed step is allowed, because reviewing an
  # earlier answer is a legitimate thing to want.
  def set_step
    requested = params[:step].presence && Onboarding.find(params[:step])
    furthest = @profile.current_onboarding_step

    if requested.nil? || requested.number > furthest.number
      redirect_to onboarding_step_path(step: furthest.slug) and return
    end

    @step = requested
  end

  def step_params
    return {} if params[:profile].blank?

    params.require(:profile).permit(*@step.permitted)
  end

  # Progress never moves backwards. Re-submitting step 1 after reaching step 3
  # corrects the answer without discarding the two steps after it.
  def advance_past(step)
    reached = [@profile.onboarding_step, step.number + 1].max
    @profile.update_column(:onboarding_step, reached)
    @profile.reload.save if @profile.onboarding_unlocked? && !@profile.onboarded?
  end

  def destination_after(step)
    next_step = Onboarding.at(step.number + 1)
    return root_path if next_step.nil?

    onboarding_step_path(step: next_step.slug)
  end
end
