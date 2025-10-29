class Utilities::IconComponent < ApplicationComponent
  erb_template <<-ERB
    <svg class="<%= size_class(size) %> <%= options[:class] %>" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="<%= options[:fill] %>" stroke="<%= options[:stroke] %>" stroke-width="<%= options[:stroke_width] %>" viewBox="<%= options[:viewbox] %>" <%= stimulus_attributes(options) %>>
      <%= render partial: partial %>
    </svg>
  ERB

  attr_reader :icon, :size, :options

  def initialize(icon, size: nil, options: {})
    @icon = icon
    @size = size
    @options = { fill: "none", viewbox: "0 0 24 24", stroke: "currentColor", stroke_width: "2" }.merge(options)
  end

  def partial
    "shared/icons/#{icon}"
  end

  def size_class(size)
    if size.present?
      "w-#{size} h-#{size}"
    else
      "w-6 h-6"
    end
  end

  private

  def stimulus_attributes(options)
    return "" unless options[:data]

    options[:data].map do |key, value|
      "data-#{key}=\"#{value}\""
    end.join(" ").html_safe
  end
end
