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
      "bg-green-50 dark:bg-green-900/20"
    when "good"
      "bg-blue-50 dark:bg-blue-900/20"
    when "fair"
      "bg-yellow-50 dark:bg-yellow-900/20"
    else
      "bg-red-50 dark:bg-red-900/20"
    end
  end

  def match_score_border_class(match_level)
    case match_level
    when "excellent"
      "border-green-200 dark:border-green-800"
    when "good"
      "border-blue-200 dark:border-blue-800"
    when "fair"
      "border-yellow-200 dark:border-yellow-800"
    else
      "border-red-200 dark:border-red-800"
    end
  end

  def match_score_text_class(match_level)
    case match_level
    when "excellent"
      "text-green-800 dark:text-green-200"
    when "good"
      "text-blue-800 dark:text-blue-200"
    when "fair"
      "text-yellow-800 dark:text-yellow-200"
    else
      "text-red-800 dark:text-red-200"
    end
  end

  # Combined class for inline badge display
  def match_score_badge_class(match_level)
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
