class ApplicationComponent < ViewComponent::Base
  include ApplicationHelper

  delegate :user_signed_in?, :current_user, :current_profile, to: :helpers

  def readable_time(created_at)
    seconds_ago = (Time.current - created_at).to_i
    case seconds_ago
    when 0..59
      "#{seconds_ago}s"
    when 60..3599
      "#{seconds_ago / 60}m"
    when 3600..86_399
      "#{seconds_ago / 3600}h"
    when 86_400..604_799
      "#{seconds_ago / 86_400}d"
    when 604_800..2_629_799
      "#{seconds_ago / 604_800}w"
    when 2_629_800..31_557_599
      "#{seconds_ago / 2_629_800}mo"
    else
      "#{seconds_ago / 31_557_600}y"
    end
  end

  def age(birth_date)
    calculated_age = Time.current.year - birth_date.year
    if Time.current.month < birth_date.month || (Time.current.month == birth_date.month && Time.current.day < birth_date.day)
      calculated_age - 1
    else
      calculated_age
    end
  end

  def match_score_bg_class(match_level)
    case match_level
    when "excellent"
      "bg-green-50 dark:bg-green-700/20"
    when "good"
      "bg-blue-50 dark:bg-blue-700/20"
    when "fair"
      "bg-orange-50 dark:bg-orange-700/20"
    else
      "bg-red-50 dark:bg-red-700/20"
    end
  end

  def match_score_border_class(match_level)
    case match_level
    when "excellent"
      "border-green-600 dark:border-green-400"
    when "good"
      "border-blue-600 dark:border-blue-400"
    when "fair"
      "border-orange-600 dark:border-orange-400"
    else
      "border-red-600 dark:border-red-400"
    end
  end

  def match_score_text_class(match_level)
    case match_level
    when "excellent"
      "text-green-600 dark:text-green-400"
    when "good"
      "text-blue-600 dark:text-blue-400"
    when "fair"
      "text-orange-600 dark:text-orange-400"
    else
      "text-red-600 dark:text-red-400"
    end
  end

  # Combined class for inline badge display
  def match_score_badge_class(match_score)
    match_level = case match_score
    when 80..100
      "excellent"
    when 60..79
      "good"
    when 40..59
      "fair"
    else
      "poor"
    end
    "#{match_score_bg_class(match_level)} #{match_score_text_class(match_level)} border #{match_score_border_class(match_level)}"
  end

  # Text formatting helper for badges and status displays
  # Converts underscored status to titleized text, or returns raw text
  def display_text(status: nil, text: nil)
    if status.present?
      status&.gsub("_", " ")&.titleize
    else
      text
    end
  end
end
