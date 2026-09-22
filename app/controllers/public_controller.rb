class PublicController < ApplicationController
  TESTIMONIAL_COUNT = 3

  def index
    @testimonials = Testimonial.publishable.ordered.limit(TESTIMONIAL_COUNT)
  end
end
