class Typography::ParagraphComponent < ApplicationComponent
  erb_template <<-ERB
    <p class="font-body text-sm lg:text-base text-zinc-600 dark:text-zinc-400">
      <%= text %>
    </p>
  ERB

  attr_reader :text

  def initialize(text:)
    @text = text
  end
end
