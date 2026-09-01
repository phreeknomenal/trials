class PublicController < ApplicationController
  TESTIMONIAL_COUNT = 3

  def index
    @testimonials = Testimonial.published.ordered.limit(TESTIMONIAL_COUNT)
  end
end
