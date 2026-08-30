class PublicController < ApplicationController
  include Paginatable

  TESTIMONIAL_COUNT = 3

  def index
    # Assigned before the early return below -- the landing page renders without
    # a query, which is exactly when the testimonial section is shown.
    @testimonials = Testimonial.published.ordered.limit(TESTIMONIAL_COUNT)

    return unless params[:query].present?

    @query = params[:query]
    result = ClinicalTrialClient.search(@query, page: current_page, page_size: page_size)

    @studies = result[:studies]
    @total_count = result[:total_count]
    @error = result[:error]
    @current_page = current_page
  end
end
