# The Dira Health mark: two mirrored triangles either side of an empty channel.
#
# The channel is empty rather than white, so the mark sits on any ground without
# a knockout plate, and the two faces are the only fills that change for dark
# mode. Geometry was measured off the source artwork rather than traced. Aspect
# is 1.816, so it is sized by height and derives its own width.
#
# Written as a literal template rather than built with tag.svg, because that
# helper downcases viewBox to viewbox. Browsers correct that when parsing inline
# SVG, but only as an HTML5 foreign-content fixup, and it is not worth relying on.
class Utilities::MarkComponent < ApplicationComponent
  erb_template <<-ERB
    <svg class="<%= height_class %> w-auto <%= options[:class] %>" viewBox="0 0 64 116" <%= accessibility_attributes %>>
      <path d="M30.6 0 L30.6 116 L0 96 Z" class="<%= left_fill %>"/>
      <path d="M33.4 0 L33.4 116 L64 96 Z" class="<%= right_fill %>"/>
    </svg>
  ERB

  # Written out rather than interpolated. Tailwind scans source for literal class
  # strings, so a class built at runtime is never emitted. See
  # Utilities::IconComponent, which interpolates and consequently renders with no
  # dimensions at sizes 16 and 20.
  HEIGHTS = {
    5 => "h-5",
    6 => "h-6",
    8 => "h-8",
    10 => "h-10",
    12 => "h-12"
  }.freeze

  attr_reader :height, :label, :options

  # Decorative by default, because it almost always sits beside the wordmark.
  # A label is only correct where the mark stands alone.
  #
  # on_dark takes the dark fills whatever the theme is, for chrome that is dark
  # in both: the admin bar is navy in light mode too, deliberately, so a
  # dark: variant would leave the mark in its light fills there.
  def initialize(height: 8, label: nil, on_dark: false, options: {})
    @height = height
    @label = label
    @on_dark = on_dark
    @options = options
  end

  def on_dark? = @on_dark

  def left_fill = on_dark? ? "fill-navy-400" : "fill-navy-600 dark:fill-navy-400"

  def right_fill = on_dark? ? "fill-sky-300" : "fill-sky-400 dark:fill-sky-300"

  def height_class
    HEIGHTS.fetch(height)
  end

  def accessibility_attributes
    return tag.attributes(aria: {hidden: true}) if label.blank?

    tag.attributes(role: "img", aria: {label: label})
  end
end
