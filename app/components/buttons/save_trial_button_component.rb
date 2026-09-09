class Buttons::SaveTrialButtonComponent < ApplicationComponent
  # Class lists are exposed as constants because the Stimulus controller swaps
  # between them on toggle. Keeping both sides reading from one definition is
  # what stops the rendered button and the toggled button from drifting apart.
  SAVED_CLASSES = "border-sky-500 bg-sky-50 text-sky-700 hover:bg-sky-100 " \
    "dark:border-sky-500 dark:bg-navy-900/30 dark:text-sky-300 dark:hover:bg-navy-900/40".freeze
  UNSAVED_CLASSES = "border-line-2 bg-surface text-ink-2 hover:border-ink-4 hover:bg-surface-2 " \
    "dark:border-line-2-on-dark dark:bg-surface-on-dark dark:text-ink-2-on-dark " \
    "dark:hover:bg-surface-2-on-dark".freeze

  SAVED_LABEL = "Saved".freeze
  UNSAVED_LABEL = "Save Trial".freeze

  def initialize(nct_id:, trial_title:, saved_trial: nil, size: "md", trial_data: nil, match_score: nil)
    @nct_id = nct_id
    @trial_title = trial_title
    @saved_trial = saved_trial
    @size = size
    @trial_data = trial_data || {}
    @match_score = match_score
  end

  def is_saved?
    @saved_trial.present?
  end

  attr_reader :nct_id

  attr_reader :trial_title

  attr_reader :match_score

  def trial_data_json
    @trial_data.to_json
  end

  def button_size_classes
    case @size
    when "sm"
      "px-3 py-1 text-sm"
    when "lg"
      "px-6 py-3 text-lg"
    else
      "px-4 py-2 text-base"
    end
  end

  def button_text
    is_saved? ? SAVED_LABEL : UNSAVED_LABEL
  end

  def button_classes
    base = "inline-flex items-center gap-2 rounded-lg border font-semibold transition-colors duration-200 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-500 #{button_size_classes}"
    state = is_saved? ? SAVED_CLASSES : UNSAVED_CLASSES

    "#{base} #{state}"
  end
end
