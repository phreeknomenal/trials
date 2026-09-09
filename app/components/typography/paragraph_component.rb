class Typography::ParagraphComponent < ApplicationComponent
  erb_template <<-ERB
    <p class="font-body text-sm lg:text-base text-ink-3 dark:text-ink-3-on-dark">
      <%= text %>
    </p>
  ERB

  attr_reader :text

  def initialize(text:)
    @text = text
  end
end
