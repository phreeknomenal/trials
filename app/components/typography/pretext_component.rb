class Typography::PretextComponent < ApplicationComponent
  erb_template <<-ERB
    <p class="text-xl lg:text-3xl font-accent font-semibold <%= color if color.present? %>"><%= text %></p>
  ERB

  attr_reader :text, :color

  def initialize(text:, color: nil)
    @text = text
    @color = color
  end
end
