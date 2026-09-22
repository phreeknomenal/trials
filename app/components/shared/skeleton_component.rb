# The loading placeholder. One shape, repeated, rather than a spinner, because a
# results page that is about to show rows should be showing where the rows will
# be.
#
# aria-hidden with a live region beside it: a screen reader gets "Loading
# studies" once, not a description of twelve grey rectangles.
class Shared::SkeletonComponent < ApplicationComponent
  SHAPES = {
    text: "h-3 rounded-full",
    heading: "h-5 rounded-full",
    card: "h-40 rounded-card",
    row: "h-24 rounded-card",
    badge: "h-6 w-20 rounded-full",
    avatar: "h-10 w-10 rounded-full"
  }.freeze

  # motion-reduce drops the pulse rather than only slowing it. A persistent
  # pulse is exactly the kind of movement the setting exists to stop.
  BASE = "block bg-surface-2 dark:bg-surface-2-on-dark animate-pulse motion-reduce:animate-none"

  attr_reader :shape, :count, :width, :label

  def initialize(shape: :text, count: 1, width: nil, label: nil)
    @shape = shape.to_sym
    @count = count
    @width = width
    @label = label
  end

  def shape_class
    SHAPES.fetch(shape) do
      raise ArgumentError,
        "Unknown skeleton shape #{shape.inspect}. Expected one of #{SHAPES.keys.join(", ")}."
    end
  end

  def classes = [BASE, shape_class, width].compact.join(" ")
end
