class Page::Trials::KeyDetails::MatchScoreCardComponent < ApplicationComponent
  def initialize(trial_score:, match_level:, score_breakdown:)
    @trial_score = trial_score
    @match_level = match_level
    @score_breakdown = score_breakdown
  end

  def match_phrase(match_level)
    case match_level
    when "excellent"
      "You're an excellent match for this study."
    when "good"
      "You're a good match for this study."
    when "fair"
      "You're a fair match for this study."
    else
      "You're a poor match for this study."
    end
  end

  def breakdown_items
    [
      { label: "Age", value: @score_breakdown[:age], icon: "calendar_month" },
      { label: "Sex", value: @score_breakdown[:sex], icon: "user" },
      { label: "Conditions", value: @score_breakdown[:conditions], icon: "microscope" },
      { label: "Location", value: @score_breakdown[:location], icon: "map_pin" },
      { label: "Study Type", value: @score_breakdown[:study_type], icon: "rectangle_stack" },
      { label: "Risk Level", value: @score_breakdown[:phase_risk], icon: "exclamation_triangle" }
    ]
  end
end
