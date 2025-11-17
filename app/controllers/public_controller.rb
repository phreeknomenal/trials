class PublicController < ApplicationController
  include Paginatable

  def index
    return unless params[:query].present?

    @query = params[:query]
    result = ClinicalTrialClient.search(@query, page: current_page, page_size: page_size)

    @studies = result[:studies]
    @total_count = result[:total_count]
    @error = result[:error]
    @current_page = current_page
  end
end
