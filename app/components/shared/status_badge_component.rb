# The seven SavedTrial statuses, plus the generic status colours, rendered as
# one badge so they stop being restated per screen.
#
# Four of the seven are a pipeline: interested, applying, contacted, enrolled.
# That is sequential data, so it runs as one hue light to dark rather than four
# unrelated colours, with enrolled taking the good token because arriving there
# is the outcome. The three terminal states sit outside the ramp: rejected is
# critical, completed and not_eligible are neutral, because neither is a low
# score on the same scale.
#
# Every badge ships with its word, and the ones carrying meaning ship with an
# icon too, so status is never colour alone.
class Shared::StatusBadgeComponent < ApplicationComponent
  BASE = "inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-semibold"

  STATUSES = {
    "interested" => {
      label: "Interested",
      classes: "bg-surface-2 text-ink-2 dark:bg-surface-2-on-dark dark:text-ink-2-on-dark"
    },
    "applying" => {
      label: "Applying",
      classes: "bg-sky-50 text-sky-700 dark:bg-navy-900/40 dark:text-sky-300"
    },
    "contacted" => {
      label: "Contacted",
      classes: "bg-sky-100 text-sky-700 dark:bg-navy-900/60 dark:text-sky-200"
    },
    "enrolled" => {
      label: "Enrolled",
      icon: "check_circle",
      classes: "bg-good/12 text-good dark:bg-good-on-dark/20 dark:text-good-on-dark"
    },
    "completed" => {
      label: "Completed",
      icon: "check",
      classes: "bg-surface-2 text-ink-3 dark:bg-surface-2-on-dark dark:text-ink-3-on-dark"
    },
    "rejected" => {
      label: "Rejected",
      icon: "close_circle",
      classes: "bg-crit/12 text-crit dark:bg-crit-on-dark/20 dark:text-crit-on-dark"
    },
    "not_eligible" => {
      label: "Not eligible",
      icon: "close",
      classes: "bg-surface-2 text-ink-3 dark:bg-surface-2-on-dark dark:text-ink-3-on-dark"
    }
  }.freeze

  attr_reader :status, :size

  def initialize(status:, size: :md)
    @status = status.to_s
    @size = size
  end

  # Raises rather than falling back to a neutral badge, because a status nobody
  # styled rendering as "Interested" is worse than a page that fails loudly.
  def config
    STATUSES.fetch(status) do
      raise ArgumentError,
        "Unknown status #{status.inspect}. Expected one of #{STATUSES.keys.join(", ")}."
    end
  end

  def label = config[:label]

  def icon = config[:icon]

  def classes = [BASE, size_class, config[:classes]].join(" ")

  private

  def size_class
    (size.to_sym == :sm) ? "px-2 py-0.5 text-[11px]" : ""
  end
end
