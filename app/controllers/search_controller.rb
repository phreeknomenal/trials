class SearchController < ApplicationController
  def index
    @conditions = Condition.order(:name)

    if search_params_present?
      Rails.logger.info("Search params present: condition=#{params[:condition]}, location=#{params[:location]}, status=#{params[:status]}, min_age=#{params[:min_age]}, max_age=#{params[:max_age]}")

      page = params[:page].to_i
      page = 1 if page < 1

      result = ClinicalTrialClient.advanced_search(
        condition: params[:condition],
        location: params[:location],
        status: params[:status].presence,
        min_age: params[:min_age],
        max_age: params[:max_age],
        page: page,
        page_size: 10
      )

      @studies = result[:studies]
      @total_count = result[:total_count]
      @error = result[:error]
      @current_page = page
    else
      Rails.logger.info("No search params present")
    end
  end

  def show
    @study = ClinicalTrialClient.get_study(params[:id])
    @error = @study[:error] if @study[:error].present?
  end

  private

  def search_params_present?
    params[:condition].present? ||
      params[:location].present? ||
      (params[:status].present? && params[:status] != "") ||
      params[:min_age].present? ||
      params[:max_age].present?
  end
end
