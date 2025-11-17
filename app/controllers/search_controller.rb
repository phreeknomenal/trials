class SearchController < ApplicationController
  include Paginatable

  def index
    @conditions = Condition.order(:name)
    return unless search_params_present?

    perform_search
  end

  def show
    @study = ClinicalTrialClient.get_study(params[:id])
    @error = @study[:error]
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
      condition: params[:condition].presence,
      location: params[:location].presence
    }
  end

  def search_params_present?
    sanitized_params.values.any?(&:present?)
  end
end
