class MyTrialsController < ApplicationController
  include Paginatable
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

  def search
    # Personalized trial search
    @conditions = Condition.order(:name)
    @profile = current_profile

    # Set default condition from profile if available
    if @profile&.conditions&.any?
      @default_condition = @profile.conditions.first.name
    end

    return unless search_params_present? || @default_condition.present?

    # Initialize or retrieve page token history for this search
    initialize_page_tokens
    perform_search
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

  def show
    @study = ClinicalTrialClient.get_study(params[:id])
    @nct_id = params[:id]  # Capture the nct_id directly
    @error = @study[:error]
    @profile = current_profile

    # Check if trial is already saved
    @saved_trial = current_user.saved_trials.find_by(nct_id: @nct_id) if current_user.present?

    # Calculate trial score for detail view
    calculate_trial_score unless @error

    # Generate eligibility checklist
    build_eligibility_checklist unless @error

    # Similar trials (same condition, exclude current)
    @similar_trials = if @profile && @study.present? && @study[:nct_id].present?
      TrialRecommendationService.new(@profile).similar_to_study(
        @study,
        exclude_nct_id: @study[:nct_id],
        limit: 5
      )
    else
      []
    end
  end

  def generate_readable_summary
    record = ReadableStudySummary.find_or_create_pending(params[:id])
    enqueue_readable_summary(record)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "readable-study-summary-content-#{params[:id]}",
          partial: "my_trials/readable_study_summary_content",
          locals: {record: record.reload, nct_id: params[:id], source_present: true}
        )
      end
      format.html { redirect_to my_trial_path(params[:id]) }
    end
  end

  private

  def enqueue_readable_summary(record)
    just_created = record.previously_new_record?

    enqueue =
      if record.completed?
        false
      elsif record.failed?
        record.update!(status: ReadableStudySummary::PENDING, error_message: nil)
        true
      elsif just_created
        true
      elsif record.stale?
        record.touch
        true
      else
        false
      end

    GenerateReadableStudySummaryJob.perform_later(params[:id]) if enqueue
  end

  def calculate_trial_score
    scorer = TrialScorer.new(@profile, @study)
    score_result = scorer.calculate_score

    return unless score_result

    @trial_score = score_result[:total]
    @score_breakdown = score_result[:breakdown]
    @match_level = score_result[:match_level]
  end

  def build_eligibility_checklist
    checker = EligibilityChecker.new(@profile, @study)
    @eligibility_checklist = checker.build_checklist
  end

  def perform_search
    current_page_num = params[:page]&.to_i || 1
    page_token = get_page_token(current_page_num)

    service = TrialSearchService.new(
      profile: @profile,
      search_params: sanitized_params,
      page: current_page_num,
      page_size: page_size,
      page_token: page_token
    )

    result = service.search(sort_by: params[:sort_by])

    @studies_with_scores = result[:studies]
    @total_count = result[:total_count]
    @error = result[:error]
    @current_page = result[:current_page]
    @has_next_page = result[:has_next_page]
    @next_page_token = result[:next_page_token]
    @prev_page_token = (current_page_num > 1) ? get_page_token(current_page_num - 1) : nil

    # Persist token from URL so Previous link can use it
    if params[:page_token].present? && current_page_num >= 2
      store_page_token(current_page_num, params[:page_token])
    end
    if result[:next_page_token].present?
      store_page_token(current_page_num + 1, result[:next_page_token])
    end
  end

  def sanitized_params
    @sanitized_params ||= {
      condition: params[:condition].presence || @default_condition,
      location: params[:location].presence || default_location
    }
  end

  def default_location
    return nil unless @profile

    # Build location from profile data
    parts = [@profile.city, @profile.state].compact
    parts.join(", ").presence
  end

  def search_params_present?
    params[:condition].present? || params[:location].present?
  end

  def pagination_params
    # Set default condition if not already set (needed for pagination links)
    @default_condition ||= @profile&.conditions&.first&.name if @profile

    {
      condition: params[:condition].presence || @default_condition,
      location: params[:location].presence,
      sort_by: params[:sort_by].presence
    }.compact
  end
  helper_method :pagination_params

  def search_key
    # Create a unique key for this search to store tokens
    "#{sanitized_params[:condition]}_#{sanitized_params[:location]}"
  end

  def initialize_page_tokens
    # Reset token storage if this is a new search (page 1 without explicit navigation)
    if params[:page].blank? || params[:page].to_i == 1
      session[:page_tokens] ||= {}
      session[:page_tokens][search_key] = {}
    end
  end

  def get_page_token(page_num)
    return nil if page_num <= 1
    # Prefer token from URL (from Next link) so pagination works across tabs/session
    return params[:page_token].presence if page_num == (params[:page]&.to_i || 1)
    session.dig(:page_tokens, search_key, page_num)
  end

  def store_page_token(page_num, token)
    session[:page_tokens] ||= {}
    session[:page_tokens][search_key] ||= {}
    session[:page_tokens][search_key][page_num] = token
  end

  def ensure_profile_exists
    unless current_user.profile
      redirect_to new_profile_path, alert: "Please create your profile first."
    end
  end
end
