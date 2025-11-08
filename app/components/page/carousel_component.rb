class Page::CarouselComponent < ApplicationComponent
  def initialize(slides:, interval: 3000)
    @slides = slides
    @interval = interval
  end

  private

  attr_reader :slides, :interval
end
