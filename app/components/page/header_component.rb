class Page::HeaderComponent < ApplicationComponent
  erb_template <<-ERB
  <div class="w-full flex flex-col items-center justify-center gap-3 mb-16">
    <span class="text-lg tracking-tight font-semibold text-zinc-600 leading-none"><%= pretext %></span>
    <%= render Typography::HeadingComponent.new(size: :heading, text: heading) %>
    <p class="text-lg text-center text-gray-600"><%= subheading %></p>
  </div>
  ERB

  attr_reader :pretext, :heading, :subheading

  def initialize(pretext:, heading:, subheading: nil)
    @pretext = pretext
    @heading = heading
    @subheading = subheading
  end
end
