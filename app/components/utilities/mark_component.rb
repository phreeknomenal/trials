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
      <path d="M30.6 0 L30.6 116 L0 96 Z" class="fill-navy-600 dark:fill-navy-400"/>
      <path d="M33.4 0 L33.4 116 L64 96 Z" class="fill-sky-400 dark:fill-sky-300"/>
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
  def initialize(height: 8, label: nil, options: {})
    @height = height
    @label = label
    @options = options
  end

  def height_class
    HEIGHTS.fetch(height)
  end

  def accessibility_attributes
    return tag.attributes(aria: {hidden: true}) if label.blank?

    tag.attributes(role: "img", aria: {label: label})
  end
end
