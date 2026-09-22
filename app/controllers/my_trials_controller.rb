class MyTrialsController < ApplicationController
  include Secured

  before_action :authenticate_user!
  before_action :ensure_profile_exists

  def index
    # Hub/Dashboard page
    @profile = current_profile
    @saved_trials_count = current_user.saved_trials.count
    @excellent_count = current_user.saved_trials.where("match_score >= ?", 80).count
    @good_count = current_user.saved_trials.where("match_score >= ? AND match_score < ?", 60, 80).count
    @fair_count = current_user.saved_trials.where("match_score >= ? AND match_score < ?", 40, 60).count

    # Generate recommendations
    @recommended_trials = TrialRecommendationService.new(@profile).recommend
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

    # Calculate score breakdowns for each trial
    @saved_trials.each do |trial|
      trial_data = {
        min_age: trial.min_age,
        max_age: trial.max_age,
        sex: nil,
        conditions: [],
        locations: [],
        study_type: trial.study_type,
        phase: trial.phase,
        status: trial.trial_status
      }

      scorer = TrialScorer.new(@profile, trial_data)
      score_result = scorer.calculate_score

      if score_result
        trial.score_breakdown = score_result[:breakdown]
      end
    end
  end

  private

  def ensure_profile_exists
    unless current_user.profile
      redirect_to new_profile_path, alert: "Please create your profile first."
    end
  end
end
