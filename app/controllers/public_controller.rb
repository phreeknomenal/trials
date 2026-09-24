class PublicController < ApplicationController
  TESTIMONIAL_COUNT = 3
  FAQ_COUNT = 5

  def index
    @testimonials = Testimonial.publishable.ordered.limit(TESTIMONIAL_COUNT)

    # Both the hero's search and the browse section read this one list. Every
    # condition links to a real search rather than to a category page that does
    # not exist.
    @conditions = Condition.order(:name)

    # A handful of the FAQ, with the rest a click away. One list means the
    # landing page cannot drift from the FAQ page, which is the same reason the
    # wizard reads TrialScorer::WEIGHTS rather than restating them.
    @faq_entries = Faq.entries.reject(&:unanswered?).first(FAQ_COUNT)
  end
end
