class Page::Trials::MatchDetailsCardComponent < ApplicationComponent
  def initialize(trial_score:, match_level:, score_breakdown:)
    @trial_score = trial_score
    @match_level = match_level
    @score_breakdown = score_breakdown
  end

  def breakdown_items
    [
      {label: "Age", value: @score_breakdown[:age]},
      {label: "Sex", value: @score_breakdown[:sex]},
      {label: "Conditions", value: @score_breakdown[:conditions]},
      {label: "Location", value: @score_breakdown[:location]},
      {label: "Study Type", value: @score_breakdown[:study_type]},
      {label: "Risk Level", value: @score_breakdown[:phase_risk]}
    ]
  end
end
