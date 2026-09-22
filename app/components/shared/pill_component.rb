# A pill filters or announces. It never performs an action, which is why it is
# the one shape allowed to go fully round: if a button went round too, a filter
# and a call to action would be the same shape.
#
# Selected state carries a check as well as a fill, so selection is not colour
# alone.
class Shared::PillComponent < ApplicationComponent
  BASE = "inline-flex items-center gap-1.5 rounded-full px-3.5 py-1.5 " \
         "text-sm font-semibold transition-colors duration-140 " \
         "focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus"

  RESTING = "border border-line-2 dark:border-line-on-dark " \
            "bg-surface dark:bg-surface-on-dark " \
            "text-ink-2 dark:text-ink-2-on-dark " \
            "hover:border-navy-600 hover:text-navy-600 " \
            "dark:hover:border-sky-300 dark:hover:text-sky-300"

  SELECTED = "border border-navy-600 bg-navy-600 text-white " \
             "dark:border-sky-400 dark:bg-sky-400 dark:text-navy-900"

  attr_reader :text, :path, :selected, :count, :options

  def initialize(text:, path: nil, selected: false, count: nil, **options)
    @text = text
    @path = path
    @selected = selected
    @count = count
    @options = options
  end

  def selected? = !!selected

  def classes = [BASE, selected? ? SELECTED : RESTING].join(" ")

  # A count reads as part of the pill, so it is dimmed rather than given its own
  # colour, which would make the pill look like two things.
  def count_class
    selected? ? "opacity-75" : "text-ink-3 dark:text-ink-3-on-dark"
  end

  # A pill that navigates is a link, a pill that toggles in place is a button,
  # and the template branches on that. aria-pressed is only meaningful on the
  # button; the link says aria-current instead.
  def link? = path.present?
end
