# What changed, on the saved study itself. The card badge says that something
# moved. This says what, once, because opening the page acknowledges it.
class Page::SavedTrials::RegistryChangeNoticeComponent < ApplicationComponent
  TONES = {
    warn: ["border-warn/30 dark:border-warn-on-dark bg-warn/10 dark:bg-warn-on-dark/20", "text-warn dark:text-warn-on-dark"],
    good: ["border-good/30 dark:border-good-on-dark bg-good/10 dark:bg-good-on-dark/20", "text-good dark:text-good-on-dark"],
    info: ["border-line dark:border-line-on-dark bg-sky-50 dark:bg-navy-900/40", "text-sky-700 dark:text-sky-300"],
    neutral: ["border-line dark:border-line-on-dark bg-surface-2 dark:bg-surface-2-on-dark", "text-ink-3 dark:text-ink-3-on-dark"]
  }.freeze

  attr_reader :change, :nct_id

  def initialize(change:, nct_id:)
    @change = change
    @nct_id = nct_id
  end

  def render? = change.present?

  def box_classes = TONES.fetch(change.tone).first

  def icon_classes = TONES.fetch(change.tone).last
end
