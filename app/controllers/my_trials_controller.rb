class MyTrialsController < ApplicationController
  include Paginatable
  include Secured
  before_action :authenticate_user!
  before_action :ensure_profile_exists

  def index
    @conditions = Condition.order(:name)
    @profile = current_profile

    # Use profile conditions if no search params provided
    if !search_params_present? && @profile&.conditions&.any?
      @default_condition = @profile.conditions.first.name
    end

    return unless search_params_present? || @default_condition.present?

    perform_search
  end

  def show
    @study = ClinicalTrialClient.get_study(params[:id])
    @error = @study[:error]
    @profile = current_profile
  end

  private

  def perform_search
    result = ClinicalTrialClient.advanced_search(
      **sanitized_params,
      page: current_page,
      page_size: page_size
    )

    @studies = result[:studies]
    @total_count = result[:total_count]
    @error = result[:error]
    @current_page = current_page
    @has_next_page = result[:next_page_token].present?
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

  def ensure_profile_exists
    unless current_user.profile
      redirect_to new_profile_path, alert: "Please create your profile first."
    end
  end
end
