class Utilities::ScoreProgressBarComponent < ApplicationComponent
  def initialize(score:, label:, match_level: nil)
    @score = score
    @label = label
    @match_level = match_level || determine_match_level(score)
  end

  private

  attr_reader :score, :label, :match_level

  def determine_match_level(score)
    case score
    when 80..100 then "excellent"
    when 60..79 then "good"
    when 40..59 then "fair"
    else "poor"
    end
  end

  def progress_bar_color_class
    case match_level
    when "excellent"
      "bg-green-500 dark:bg-green-400"
    when "good"
      "bg-blue-500 dark:bg-blue-400"
    when "fair"
      "bg-orange-500 dark:bg-orange-400"
    else
      "bg-red-500 dark:bg-red-400"
    end
  end

  def progress_bar_bg_class
    "bg-zinc-200 dark:bg-zinc-600"
  end
end
