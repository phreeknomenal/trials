class Buttons::SaveTrialButtonComponent < ApplicationComponent
  # Class lists are exposed as constants because the Stimulus controller swaps
  # between them on toggle. Keeping both sides reading from one definition is
  # what stops the rendered button and the toggled button from drifting apart.
  SAVED_CLASSES = "border-blue-500 bg-blue-50 text-blue-700 hover:bg-blue-100".freeze
  UNSAVED_CLASSES = "border-gray-300 bg-white text-gray-700 hover:bg-gray-50".freeze

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
    base = "inline-flex items-center gap-2 rounded-lg border font-medium transition-colors duration-200 #{button_size_classes}"
    state = is_saved? ? SAVED_CLASSES : UNSAVED_CLASSES

    "#{base} #{state}"
  end
end
