class Utilities::ScoreProgressBarComponent < ApplicationComponent
  def initialize(score:, label:, match_level: nil)
    @score = score
    @label = label
    # match_level_for lives on ApplicationComponent. This class previously
    # carried its own copy of the thresholds and its own green/blue/orange/red
    # case, which meant a fifth definition of the tiers that the recolour in
    # #115 did not reach.
    @match_level = match_level || match_level_for(score)
  end

  private

  attr_reader :score, :label, :match_level

  def progress_bar_color_class
    match_score_bar_class(match_level)
  end

  def progress_bar_bg_class
    "bg-surface-2 dark:bg-surface-2-on-dark"
  end
end
