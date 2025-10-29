class Typography::SubheadingComponent < ApplicationComponent
  erb_template <<-ERB
    <p class="text-sm <%= text_color(color) %>">
      <%= text %>
    </p>
  ERB

  attr_reader :text, :color

  def initialize(text:, color: nil)
    @text = text
    @color = color
  end

  def text_color(color)
    color || "text-secondary-600"
  end
end
