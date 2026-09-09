class Page::SavedTrials::MatchScoreCardComponent < ApplicationComponent
  def initialize(match_score:)
    @match_score = match_score
  end

  def match_level
    case @match_score
    when 80..100
      "excellent"
    when 60..79
      "good"
    when 40..59
      "fair"
    else
      "poor"
    end
  end

  def score_color_classes
    case match_level
    when "excellent"
      "text-good"
    when "good"
      "text-info"
    when "fair"
      "text-warn"
    when "poor"
      "text-crit"
    end
  end

  def score_badge_classes
    case match_level
    when "excellent"
      "bg-good text-white"
    when "good"
      "bg-info text-white"
    when "fair"
      "bg-warn text-white"
    when "poor"
      "bg-crit text-white"
    end
  end

  def score_label
    case match_level
    when "excellent"
      "Excellent Match"
    when "good"
      "Good Match"
    when "fair"
      "Fair Match"
    when "poor"
      "Poor Match"
    end
  end
end
