class Page::Trials::KeyDetailsComponent < ApplicationComponent
  def initialize(study:, trial_score: nil, match_level: nil, score_breakdown: nil)
    @study = study
    @trial_score = trial_score
    @match_level = match_level
    @score_breakdown = score_breakdown
  end
end
