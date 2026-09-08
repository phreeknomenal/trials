class Buttons::ButtonComponent < ApplicationComponent
  # Named for the job the button does, not the colour it happens to be. The old
  # names were hues, "lavender", "coral", "blue", which stopped meaning anything
  # the moment the palette changed.
  #
  # Five call sites were passing a colour this component had no case for and
  # silently getting the default. One of them was DeleteButtonComponent, so
  # every delete in the app rendered as an ordinary neutral button.
  VARIANTS = {
    "primary" => "border border-navy-600 text-white bg-navy-600 " \
                 "hover:border-navy-700 hover:bg-navy-700",

    "secondary" => "border border-navy-600 text-navy-600 bg-transparent " \
                   "dark:border-navy-300 dark:text-navy-300 " \
                   "hover:bg-navy-600 hover:text-white hover:border-navy-600 " \
                   "dark:hover:bg-navy-400 dark:hover:text-navy-900",

    "quiet" => "border border-transparent text-navy-600 bg-transparent " \
               "dark:text-navy-300 " \
               "hover:bg-sky-50 dark:hover:bg-navy-900/30",

    "destructive" => "border border-crit text-crit bg-transparent " \
                     "dark:border-crit-on-dark dark:text-crit-on-dark " \
                     "hover:bg-crit hover:text-white hover:border-crit " \
                     "dark:hover:bg-crit-on-dark dark:hover:text-navy-900"
  }.freeze

  DEFAULT_VARIANT = "secondary"

  attr_reader :path, :text, :icon, :color, :icon_position

  def initialize(path:, text:, color: nil, icon: nil, icon_position: "left")
    @path = path
    @text = text
    @icon = icon
    @color = color
    @icon_position = icon_position
  end

  # Raises rather than falling back, because the previous behaviour was to
  # render the wrong button and say nothing.
  def color_styles
    variant = color.presence || DEFAULT_VARIANT

    VARIANTS.fetch(variant) do
      raise ArgumentError,
        "Unknown button variant #{color.inspect}. Expected one of #{VARIANTS.keys.join(", ")}."
    end + " transition-all"
  end
end
