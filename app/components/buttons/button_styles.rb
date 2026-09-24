# The one place a button's look is decided, shared by ButtonComponent, which
# renders a link, and Forms::SubmitComponent, which renders an input.
#
# They used to each carry their own list. ButtonComponent knew four variants in
# navy; SubmitComponent knew three in a `primary` colour that was defined as a
# near-black oklch, plus a `secondary-*` ramp that was never defined at all. So
# a form with a link-styled button beside a submit showed two different colours,
# two different radii, and one dead focus ring.
module Buttons::ButtonStyles
  # Named for the job the button does, not the colour it happens to be. The old
  # names were hues, "lavender", "coral", "blue", which stopped meaning anything
  # the moment the palette changed.
  VARIANTS = {
    "primary" => "border border-navy-600 text-white bg-navy-600 " \
                 "hover:border-navy-700 hover:bg-navy-700 " \
                 "active:bg-navy-800 active:border-navy-800",

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
                     "dark:hover:bg-crit-on-dark dark:hover:text-navy-900",

    # For a button sitting on a navy-600 panel, where the ordinary variants have
    # nothing to work against. `secondary` is navy-600 text on a navy-600 border
    # with no fill, so on a navy-600 ground it is the same colour as what is
    # behind it: a contrast ratio of 1 to 1, an invisible button.
    #
    # That is not hypothetical. The landing page's closing call to action, the
    # last thing on the page and the main thing it asks anyone to do, rendered
    # two buttons nobody could see in light mode. They were legible in dark only
    # because the dark: rules swap the text to navy-300.
    #
    # These do not carry dark: rules. The panel is navy in both themes, so the
    # button on it should not change.
    "primary-on-navy" => "border border-white bg-white text-navy-700 " \
                         "hover:bg-navy-50 hover:border-navy-50 " \
                         "active:bg-navy-100 active:border-navy-100",

    "secondary-on-navy" => "border border-white text-white bg-transparent " \
                           "hover:bg-white hover:text-navy-700"
  }.freeze

  DEFAULT_VARIANT = "secondary"

  # :focus-visible rather than :focus, so a mouse click does not leave a ring
  # behind. Two pixels at two pixels of offset, per the style guide.
  FOCUS = "focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus"

  # 45% opacity, no hover, not-allowed. Stated once so a disabled button looks
  # the same whichever component drew it.
  DISABLED = "disabled:opacity-45 disabled:cursor-not-allowed " \
             "disabled:hover:bg-navy-600 disabled:hover:border-navy-600"

  BASE = "inline-flex items-center justify-center gap-2 rounded-control " \
         "font-medium transition-colors duration-140 cursor-pointer"

  # Raises rather than falling back, because the previous behaviour was to
  # render the wrong button and say nothing. Five call sites were passing a
  # colour ButtonComponent had no case for, one of them DeleteButtonComponent,
  # so every delete in the app rendered as an ordinary neutral button.
  def self.variant(name)
    VARIANTS.fetch(name.presence || DEFAULT_VARIANT) do
      raise ArgumentError,
        "Unknown button variant #{name.inspect}. Expected one of #{VARIANTS.keys.join(", ")}."
    end
  end

  def self.classes(name, size: "px-4 py-2 text-sm")
    [BASE, size, variant(name), FOCUS, DISABLED].join(" ")
  end
end
