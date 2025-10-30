class Typography::HeadingComponent < ApplicationComponent
  erb_template <<-ERB
    <h2 class="inline-flex flex-col lg:flex-row lg:items-center gap-y-2 tracking-tight <%= styles %> <%= color if color.present? %>">
      <%= content if content.present? %>
      <%= text %>
    </h2>
  ERB

  attr_reader :size, :text, :color

  def initialize(size:, text:, color: nil)
    @size = size
    @text = text
    @color = color
  end

  def styles
    case size
    when :h2
      "text-3xl font-medium"
    when :h3
      "text-2xl font-medium"
    when :h4
      "text-xl font-medium"
    when :h5
      "text-lg font-medium"
    when :h6
      "text-base font-medium"
    when :h7
      "text-sm font-semibold leading-6"
    when :heading
      "text-5xl font-medium"
    else
      "text-lg font-medium"
    end
  end
end
