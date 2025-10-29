class Typography::ParagraphComponent < ApplicationComponent
  erb_template <<-ERB
    <p class="text-gray-600 font-light">
      <%= text %>
    </p>
  ERB

  attr_reader :text

  def initialize(text:)
    @text = text
  end
end
