class Typography::PretextComponent < ApplicationComponent
  erb_template <<-ERB
    <p class="<%= styles %> tracking-tight font-semibold text-zinc-600"><%= text %></p>
  ERB

  attr_reader :text, :size

  def initialize(text:, size: :small)
    @text = text
    @size = size
  end

  def styles
    case size
    when :small
      "text-sm"
    when :medium
      "text-base"
    end
  end
end
