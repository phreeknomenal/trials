class PublicController < ApplicationController
  def index
    if params[:query].present?
      @query = params[:query]
      page = params[:page].to_i
      page = 1 if page < 1

      result = ClinicalTrialClient.search(@query, page: page, page_size: 10)
      @studies = result[:studies]
      @total_count = result[:total_count]
      @error = result[:error]
      @current_page = page
    end
  end
end
