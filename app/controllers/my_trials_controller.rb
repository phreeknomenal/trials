class MyTrialsController < ApplicationController
  include Secured

  # How long a study can sit in applying or contacted before the dashboard
  # raises it. Long enough that a site has had a fair chance to answer.
  STALE_AFTER = 5.days

  before_action :authenticate_user!
  before_action :ensure_profile_exists

  def index
    @profile = current_profile
    saved = current_user.saved_trials

    @saved_trials_count = saved.count

    # Grouped by status rather than by score tier. The tiers answered "how well
    # do these fit me", which the score on each card already says; status
    # answers "what have I done about them", which is the question a dashboard
    # is for and the only one whose answer the person controls.
    @counts_by_status = saved.group(:status).count
    @recent_saved = saved.order(updated_at: :desc).limit(3)

    # Studies where the person is mid-conversation and nothing has moved.
    @awaiting_reply = saved.where(status: [SavedTrial::APPLYING, SavedTrial::CONTACTED])
      .where(updated_at: ..STALE_AFTER.ago)
      .order(:updated_at)
      .limit(3)

    @recommendations = TrialRecommendationService.new(@profile).recommend
    @strength = ProfileStrength.new(@profile) if @profile
    # The panel reports sections answered, the same measure the profile page
    # shows, so the two cannot disagree about how complete a profile is.
    @sections = ProfileSections.new(@profile) if @profile
  end

  def saved_trials
    # Redirect to the saved trials index
    redirect_to saved_trials_path
  end

  def trial_comparison
    # Comparison page - gets trial IDs from params (comma-separated string or array from form)
    @profile = current_profile
    raw_ids = params[:ids]
    trial_ids = raw_ids.is_a?(Array) ? raw_ids : (raw_ids&.split(",") || [])
    trial_ids = trial_ids.map(&:to_i).reject(&:zero?)

    if trial_ids.blank? || trial_ids.length < 2
      redirect_to my_trials_saved_trials_path, alert: "Please select at least 2 trials to compare"
      return
    end

    if trial_ids.length > 3
      redirect_to my_trials_saved_trials_path, alert: "You can compare a maximum of 3 trials"
      return
    end

    @saved_trials = current_user.saved_trials.where(id: trial_ids)

    if @saved_trials.count != trial_ids.length
      redirect_to my_trials_saved_trials_path, alert: "Some trials not found"
      return
    end

    # Scored against the study the registry holds, not against the saved columns.
    # saved_trials stores no conditions and no locations, which are 40 of the 100
    # points, so scoring from them gave every comparison a different number from
    # the one the results page showed for the same study.
    @scored = ComparisonScorer.new(profile: @profile, saved_trials: @saved_trials).call

    # The breakdown component reads score_breakdown off the record, so the freshly
    # scored values are assigned back to the in-memory objects it is given.
    @scored.each do |scored|
      scored.saved_trial.score_breakdown = scored.breakdown
      scored.saved_trial.match_level = scored.match_level
    end

    @scored_by_id = @scored.index_by { |scored| scored.saved_trial.id }
  end

  private

  def ensure_profile_exists
    unless current_user.profile
      redirect_to new_profile_path, alert: "Please create your profile first."
    end
  end
end
