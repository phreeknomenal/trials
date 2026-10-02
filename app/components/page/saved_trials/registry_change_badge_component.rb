# The card's flag for a study that moved on the registry since the person last
# opened it. Sits beside the status badge, in the same shape, so the row reads
# as "what you did about it" then "what the study did".
class Page::SavedTrials::RegistryChangeBadgeComponent < ApplicationComponent
  BASE = "inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-semibold"

  TONES = {
    warn: "bg-warn/12 text-warn dark:bg-warn-on-dark/20 dark:text-warn-on-dark",
    good: "bg-good/12 text-good dark:bg-good-on-dark/20 dark:text-good-on-dark",
    info: "bg-sky-50 text-sky-700 dark:bg-navy-900/40 dark:text-sky-300",
    neutral: "bg-surface-2 text-ink-2 dark:bg-surface-2-on-dark dark:text-ink-2-on-dark"
  }.freeze

  attr_reader :change

  def initialize(change:)
    @change = change
  end

  def render? = change.present?

  def classes = [BASE, TONES.fetch(change.tone)].join(" ")
end
