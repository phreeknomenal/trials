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
    @options = {fill: "none", viewbox: "0 0 24 24", stroke: "currentColor", stroke_width: "2"}.merge(options)
  end

  def partial
    "shared/icons/#{icon}"
  end

  # Written out rather than interpolated. Tailwind scans source for literal class
  # strings, so "w-#{size} h-#{size}" is never seen by the scanner and the class
  # is never emitted. Sizes 4, 5, 6, 12 and 14 only worked because those literals
  # happen to appear elsewhere in the views; 8 was half broken, w-8 missing but
  # h-8 present; 16 and 20 rendered with no dimensions at all.
  SIZES = {
    3 => "w-3 h-3",
    4 => "w-4 h-4",
    5 => "w-5 h-5",
    6 => "w-6 h-6",
    8 => "w-8 h-8",
    10 => "w-10 h-10",
    12 => "w-12 h-12",
    14 => "w-14 h-14",
    16 => "w-16 h-16",
    20 => "w-20 h-20",
    24 => "w-24 h-24"
  }.freeze

  DEFAULT_SIZE_CLASS = SIZES.fetch(6)

  # Raises rather than falling back, because the previous failure was silent: an
  # unsupported size rendered an icon with no dimensions and nothing said so.
  def size_class(size)
    return DEFAULT_SIZE_CLASS if size.blank?

    SIZES.fetch(size.to_i) do
      raise ArgumentError,
        "Unsupported icon size #{size.inspect}. Add it to Utilities::IconComponent::SIZES " \
        "so Tailwind emits the class."
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
