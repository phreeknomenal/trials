class Page::Cards::CardComponent < ApplicationComponent
  erb_template <<-ERB
    <div class="<%= container_classes %>">
      <% if image_first? %>
        <div class="<%= image_wrapper_classes %>">
          <%= image_tag image, class: image_classes %>
        </div>
      <% end %>

      <div class="<%= content_wrapper_classes %>">
        <div class="flex flex-col gap-3">
          <%= render Typography::PretextComponent.new(text: pretext) %>
          <%= render Typography::HeadingComponent.new(size: :h3, text: title) %>
          <%= render Typography::ParagraphComponent.new(text: subtitle) %>
        </div>
        <div class="mt-4">
          <%= link_to "#", class: "flex items-center gap-1 font-semibold text-lg text-zinc-600 hover:text-blue-600 transition group" do %>
            <span><%= link_text %></span>
            <%= render Utilities::IconComponent.new("arrow_right", size: 6) %>
          <% end %>
        </div>
      </div>

      <% unless image_first? %>
        <div class="<%= image_wrapper_classes %>">
          <%= image_tag image, class: image_classes %>
        </div>
      <% end %>
    </div>
  ERB

  attr_reader :image, :pretext, :title, :subtitle, :link_text, :type

  def initialize(image:, pretext:, title:, subtitle:, link_text:, type: :top)
    @image = image
    @pretext = pretext
    @title = title
    @subtitle = subtitle
    @link_text = link_text
    @type = type
  end

  private

  def vertical?
    [:top, :bottom].include?(type)
  end

  def horizontal?
    [:left, :right].include?(type)
  end

  def image_first?
    [:top, :left].include?(type)
  end

  def container_classes
    base = "w-full h-full border border-zinc-300 dark:border-zinc-700 rounded-lg overflow-hidden bg-white dark:bg-zinc-900"
    if horizontal?
      "#{base} flex"
    else
      "#{base} flex flex-col"
    end
  end

  def image_wrapper_classes
    horizontal? ? "w-1/2 border-x border-zinc-300 dark:border-zinc-700" : "border-y border-zinc-300 dark:border-zinc-700"
  end

  def image_classes
    horizontal? ? "w-full h-full object-cover" : "w-full h-48 object-cover"
  end

  def content_wrapper_classes
    if horizontal?
      "w-1/2 h-full flex flex-col justify-center p-6"
    else
      "p-6 flex-grow flex flex-col justify-between"
    end
  end
end
