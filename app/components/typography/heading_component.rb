class Typography::HeadingComponent < ApplicationComponent
  erb_template <<-ERB
    <h2 class="inline-flex flex-col lg:flex-row lg:items-center gap-y-2 tracking-tight <%= styles %> <%= color if color.present? %> text-zinc-900 dark:text-zinc-300">
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
      "text-3xl lg:text-5xl font-bold"
    when :h3
      "text-4xl font-bold"
    when :h4
      "text-3xl font-bold"
    when :h5
      "text-2xl font-bold"
    when :h6
      "text-xl font-bold"
    when :h7
      "text-lg font-semibold leading-6"
    when :h8
      "text-base font-semibold leading-6"
    when :h9
      "text-sm font-semibold leading-6"
    when :h10
      "text-xs font-semibold leading-6"
    when :heading
      "text-5xl font-bold"
    else
      "text-lg font-bold"
    end
  end
end
