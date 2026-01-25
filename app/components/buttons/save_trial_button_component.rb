class Buttons::SaveTrialButtonComponent < ApplicationComponent
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

  def nct_id
    @nct_id
  end

  def trial_title
    @trial_title
  end

  def trial_data_json
    @trial_data.to_json
  end

  def match_score
    @match_score
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

  def button_icon
    is_saved? ? "bookmark" : "bookmark-outline"
  end

  def button_text
    is_saved? ? "Saved" : "Save Trial"
  end

  def button_classes
    base_classes = "inline-flex items-center gap-2 rounded-lg border font-medium transition-colors duration-200 #{button_size_classes}"

    if is_saved?
      "#{base_classes} border-blue-500 bg-blue-50 text-blue-700 hover:bg-blue-100"
    else
      "#{base_classes} border-gray-300 bg-white text-gray-700 hover:bg-gray-50"
    end
  end
end
