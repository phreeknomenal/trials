class MyTrialsController < ApplicationController
  include Paginatable
  include Secured
  before_action :authenticate_user!
  before_action :ensure_profile_exists

  def index
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

  def show
    @study = ClinicalTrialClient.get_study(params[:id])
    @error = @study[:error]
    @profile = current_profile

    # Calculate trial score for detail view
    calculate_trial_score unless @error
  end

  private

  def calculate_trial_score
    scorer = TrialScorer.new(@profile, @study)
    score_result = scorer.calculate_score

    return unless score_result

    @trial_score = score_result[:total]
    @score_breakdown = score_result[:breakdown]
    @match_level = score_result[:match_level]
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

    # Store the next page token for future use (only for standard search)
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
    parts = [ @profile.city, @profile.state ].compact
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
