class Page::HeaderComponent < ApplicationComponent
  erb_template <<-ERB
  <div class="w-full flex flex-col <%= position_classes %> justify-center gap-3 mb-16">
    <% if pretext.present? %>
      <%= render Typography::PretextComponent.new(text: pretext, color: "text-lavender-600") %>
    <% end %>
    <%= render Typography::HeadingComponent.new(size: :heading, text: heading) %>
    <% if subheading.present? %>
      <%= render Typography::ParagraphComponent.new(text: subheading) %>
    <% end %>
  </div>
  ERB

  attr_reader :pretext, :heading, :subheading, :position

  def initialize(heading:, subheading: nil, pretext: nil, position: "center")
    @pretext = pretext
    @heading = heading
    @subheading = subheading
    @position = position
  end

  def position_classes
    case position
    when :center
      "items-center"
    when :left
      "items-start"
    when :right
      "items-end"
    else
      "items-center"
    end
  end
end
