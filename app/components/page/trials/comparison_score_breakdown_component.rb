class Page::Trials::ComparisonScoreBreakdownComponent < ApplicationComponent
  def initialize(trials:)
    @trials = trials
    @criteria = [ "Age", "Sex", "Conditions", "Location", "Study Type", "Risk Level" ]
    @criteria_keys = [ :age, :sex, :conditions, :location, :study_type, :phase_risk ]
  end

  def score_for_trial_and_criteria(trial, criteria_key)
    trial.score_breakdown&.dig(criteria_key) || 0
  end

  def highest_score_for_criteria(criteria_key)
    @trials.map { |trial| score_for_trial_and_criteria(trial, criteria_key) }.max || 0
  end

  def is_highest_score?(score, criteria_key)
    score == highest_score_for_criteria(criteria_key) && score > 0
  end

  def get_icon_for_criteria(label)
    case label
    when "Age"
      "calendar_month"
    when "Sex"
      "user"
    when "Conditions"
      "microscope"
    when "Location"
      "map_pin"
    when "Study Type"
      "rectangle_stack"
    when "Risk Level"
      "exclamation_triangle"
    else
      "check_circle"
    end
  end

  def score_match_level(score)
    case score
    when 80..100 then "excellent"
    when 60..79 then "good"
    when 40..59 then "fair"
    else "poor"
    end
  end

  def match_level_for_score(score)
    score_match_level(score)
  end

  def score_label_for_score(score)
    case score_match_level(score)
    when "excellent"
      "Excellent"
    when "good"
      "Good"
    when "fair"
      "Fair"
    when "poor"
      "Poor"
    end
  end

  def get_text_color_for_score(score)
    case score_match_level(score)
    when "excellent"
      "text-green-900 dark:text-green-100"
    when "good"
      "text-blue-900 dark:text-blue-100"
    when "fair"
      "text-orange-900 dark:text-orange-100"
    else
      "text-red-900 dark:text-red-100"
    end
  end
end
