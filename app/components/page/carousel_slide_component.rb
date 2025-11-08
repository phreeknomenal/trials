class Page::CarouselSlideComponent < ApplicationComponent
  erb_template <<-ERB
    <%= image_tag image, class: "w-full h-124 object-cover object-center mx-auto mb-8 rounded-full", alt: image_alt %>
    <h1 class="text-2xl lg:text-3xl text-center font-bold tracking-tight text-lavender-600 mb-2"><%= title %></h1>
    <p class="font-normal text-base text-zinc-600 dark:text-zinc-400 text-center">
      <%= description %>
    </p>
  ERB

  def initialize(image:, title:, description:, image_alt: nil)
    @image = image
    @title = title
    @description = description
    @image_alt = image_alt || title
  end

  private

  attr_reader :image, :title, :description, :image_alt
end
