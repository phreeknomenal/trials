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
      "text-green-600"
    when "good"
      "text-blue-600"
    when "fair"
      "text-amber-600"
    when "poor"
      "text-red-600"
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
