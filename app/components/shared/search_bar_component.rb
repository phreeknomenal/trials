# The hero control, and the reason the landing page no longer opens on a list of
# trials nobody asked for.
#
# Two variants. The full one leads a page: 16px radius, a label above every
# field, and popular conditions offered underneath. The compact one sits above
# results at 14px, one line, with an Update button, because by then the person
# has already told us what they want and is adjusting it.
#
# Every field keeps a visible label. A placeholder alone disappears the moment
# someone types, which is exactly when they most need to know what the box was
# for.
class Shared::SearchBarComponent < ApplicationComponent
  VARIANTS = %i[full compact].freeze

  # Named conditions rather than "e.g. a condition", because a real example
  # tells you the shape of the answer and a generic one does not.
  PLACEHOLDER = "Breast cancer, type 2 diabetes, migraine".freeze

  DISTANCES = [
    ["Within 25 miles", "25"],
    ["Within 50 miles", "50"],
    ["Within 100 miles", "100"],
    ["Any distance", ""]
  ].freeze

  attr_reader :url, :variant, :conditions, :condition, :location, :distance, :popular

  def initialize(url:, variant: :full, conditions: [], condition: nil, location: nil, distance: nil, popular: [])
    @url = url
    @variant = variant.to_sym
    @conditions = conditions
    @condition = condition
    @location = location
    @distance = distance
    @popular = popular

    return if VARIANTS.include?(@variant)

    raise ArgumentError, "Unknown search bar variant #{variant.inspect}. Expected one of #{VARIANTS.join(", ")}."
  end

  def full? = variant == :full

  def compact? = variant == :compact

  # The container sits one rung above the controls inside it, so a 12px field
  # inside a 16px bar reads settled. Compact drops to 14px because it is a
  # toolbar rather than the subject of the page.
  def container_class
    [
      "bg-surface dark:bg-surface-on-dark border border-line dark:border-line-on-dark",
      full? ? "rounded-search p-3 shadow-sm" : "rounded-card p-2"
    ].join(" ")
  end

  def layout_class
    full? ? "flex flex-col gap-2 lg:flex-row lg:items-end" : "flex flex-col gap-2 sm:flex-row sm:items-center"
  end

  def field_class
    Forms::FieldStyles.input(extra: full? ? "border-transparent bg-transparent" : nil)
  end

  def label_class
    full? ? "block text-xs font-bold uppercase tracking-wide text-ink-3 dark:text-ink-3-on-dark mb-1 px-1" : "sr-only"
  end

  # 60px tall on the full bar so it matches the stacked label-and-field beside
  # it rather than floating.
  def submit_class
    Buttons::ButtonStyles.classes(
      "primary",
      size: full? ? "px-7 h-[60px] text-base" : "px-4 py-2 text-sm"
    )
  end

  def submit_text = full? ? "Search" : "Update"

  # A hairline between fields rather than four separate boxes, so the bar reads
  # as one control.
  def divider_class
    full? ? "hidden lg:block w-px self-stretch bg-line dark:bg-line-on-dark my-1" : "hidden"
  end

  def condition_options
    conditions.map { |c| c.respond_to?(:name) ? [c.name, c.name] : [c, c] }
  end

  # Four at most. A fifth stops being a shortcut and starts being a list.
  def popular_conditions = popular.first(4)

  def path_for(name)
    "#{url}?#{{condition: name}.to_query}"
  end
end
