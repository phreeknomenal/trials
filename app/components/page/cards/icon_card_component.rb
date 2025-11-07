class Page::Cards::IconCardComponent < ApplicationComponent
  erb_template <<-ERB
    <% if style == :default %>
      <div class="w-full h-full flex gap-x-4 border border-zinc-300 dark:border-zinc-700 rounded-lg p-6 space-y-3">
        <div class="w-24 text-lavender-600">
          <%= render Utilities::IconComponent.new(icon, size: 14) %>
        </div>
        <div class="space-y-3">
          <%= render Typography::HeadingComponent.new(size: :h3, text: title) %>
          <%= render Typography::ParagraphComponent.new(text: subtitle) %>
        </div>
      </div>
    <% elsif style == :top %>
      <div class="w-full h-full flex flex-col gap-x-4 border border-zinc-300 dark:border-zinc-700 rounded-lg p-6 space-y-3">
        <div class="w-14 h-14 text-lavender-600">
          <%= render Utilities::IconComponent.new(icon, size: 14) %>
        </div>
        <div class="space-y-3">
          <%= render Typography::HeadingComponent.new(size: :h3, text: title) %>
          <%= render Typography::ParagraphComponent.new(text: subtitle) %>
        </div>
        <div class="mt-auto">
          <%= link_to path, class: "flex items-center gap-1 font-semibold text-lg text-lavender-600 hover:text-coral-600 transition group" do %>
            <span>Learn More</span>
            <%= render Utilities::IconComponent.new("arrow_right", size: 6) %>
          <% end %>
        </div>
      </div>
    <% end %>
  ERB

  attr_reader :icon, :title, :subtitle, :style, :path

  def initialize(icon:, title:, subtitle:, style: :default, path: nil)
    @icon = icon
    @title = title
    @subtitle = subtitle
    @style = style
    @path = path || "#"
  end
end
