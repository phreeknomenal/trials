# The one search. Signed in and signed out are states of these two actions, not
# separate controllers: MyTrialsController#search and #show used to be a parallel
# copy of them, and the two drifted.
#
# The difference between the two states is entirely "is there a profile". Every
# service below already answers nil for a nil profile -- TrialScorer#calculate_score
# returns nil, EligibilityChecker#build_checklist returns [] -- so there is no
# branch here, only a profile that may not be there.
class SearchController < ApplicationController
  include Paginatable
  include Secured

  def index
    @conditions = Condition.order(:name)
    @profile = current_profile
    @default_condition = @profile&.conditions&.first&.name

    return unless search_params_present? || @default_condition.present?

    initialize_page_tokens
    perform_search
    load_saved_trials
  end

  def show
    @nct_id = params[:id]
    @study = ClinicalTrialClient.get_study(@nct_id)
    @error = @study[:error]
    @profile = current_profile
    @saved_trial = current_user.saved_trials.find_by(nct_id: @nct_id) if current_user

    return if @error

    calculate_trial_score
    @eligibility_checklist = EligibilityChecker.new(@profile, @study).build_checklist
    @similar_trials = similar_trials
  end

  private

  def perform_search
    current_page_num = params[:page]&.to_i || 1

    result = TrialSearchService.new(
      profile: @profile,
      search_params: sanitized_params,
      page: current_page_num,
      page_size: page_size,
      page_token: get_page_token(current_page_num),
      filters: filters
    ).search(sort_by: params[:sort_by])

    @studies = result[:studies]
    @facets = result[:facets]
    @refined = result[:refined]
    @total_count = result[:total_count]
    @error = result[:error]
    @current_page = result[:current_page]
    @has_next_page = result[:has_next_page]
    @next_page_token = result[:next_page_token]
    @prev_page_token = (current_page_num > 1) ? get_page_token(current_page_num - 1) : nil

    # Persist the token from the URL so Previous can use it on the way back.
    if params[:page_token].present? && current_page_num >= 2
      store_page_token(current_page_num, params[:page_token])
    end

    if result[:next_page_token].present?
      store_page_token(current_page_num + 1, result[:next_page_token])
    end
  end

  # One query for the whole page rather than one per card. Keyed by nct_id
  # because that is what a result row has; saved trials have their own ids and
  # the row does not know them.
  def load_saved_trials
    return if current_user.blank? || @studies.blank?

    nct_ids = @studies.filter_map { |study| study[:nct_id] }
    @saved_trials_by_nct_id = current_user.saved_trials.where(nct_id: nct_ids).index_by(&:nct_id)
  end

  def calculate_trial_score
    score_result = TrialScorer.new(@profile, @study).calculate_score
    return unless score_result

    @trial_score = score_result[:total]
    @score_breakdown = score_result[:breakdown]
    @match_level = score_result[:match_level]
  end

  def similar_trials
    return [] unless @profile && @study[:nct_id].present?

    TrialRecommendationService.new(@profile).similar_to_study(
      @study,
      exclude_nct_id: @study[:nct_id],
      limit: 5
    )
  end

  # The condition falls back to the profile's first condition and the location to
  # the profile's city and state, so a signed-in visitor lands on results rather
  # than an empty form. Signed out, both are simply nil.
  def sanitized_params
    @sanitized_params ||= {
      condition: params[:condition].presence || @default_condition,
      location: params[:location].presence || profile_location
    }
  end

  def profile_location
    return nil unless @profile

    [@profile.city, @profile.state].compact.join(", ").presence
  end

  def search_params_present?
    params[:condition].present? || params[:location].present?
  end

  # The registry cannot filter by phase or study type, so these are applied over
  # a fetched batch. See TrialSearchService.
  def filters
    @filters ||= {
      phase: Array(params[:phase]).compact_blank,
      study_type: Array(params[:study_type]).compact_blank,
      hide_ineligible: params[:hide_ineligible]
    }
  end
  helper_method :filters

  def filters_active?
    filters[:phase].any? || filters[:study_type].any? || filters[:hide_ineligible].present?
  end
  helper_method :filters_active?

  # Everything a link has to carry to keep the same search. Dropping a filter
  # here is how a paginated page silently loses its refinements.
  def pagination_params
    {
      condition: params[:condition].presence || @default_condition,
      location: params[:location].presence,
      sort_by: params[:sort_by].presence,
      phase: filters[:phase].presence,
      study_type: filters[:study_type].presence,
      hide_ineligible: filters[:hide_ineligible].presence
    }.compact
  end
  helper_method :pagination_params

  def search_key
    "#{sanitized_params[:condition]}_#{sanitized_params[:location]}"
  end

  def initialize_page_tokens
    # A new search, rather than navigation within one, resets the stored tokens.
    return unless params[:page].blank? || params[:page].to_i == 1

    session[:page_tokens] ||= {}
    session[:page_tokens][search_key] = {}
  end

  def get_page_token(page_num)
    return nil if page_num <= 1

    session.dig(:page_tokens, search_key, page_num)
  end

  def store_page_token(page_num, token)
    session[:page_tokens] ||= {}
    session[:page_tokens][search_key] ||= {}
    session[:page_tokens][search_key][page_num] = token
  end
end
