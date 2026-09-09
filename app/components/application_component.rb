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

  # A match score is 0 to 100, which is sequential data, so the tiers are one
  # hue running light to dark rather than four unrelated colours. The previous
  # scheme used green, blue, orange and red: it lost the ordering, put red
  # against green for the 8% of men who cannot separate them, and made red read
  # as danger when a poor match only means the study is not for you.
  #
  # The panel tint stays constant and legible; the text depth carries the ramp,
  # because the score itself is set in that colour at up to 6xl.
  #
  # INELIGIBLE leaves the ramp entirely. It is a hard stop from a failed
  # criterion, not a low score, so it takes neutral grey. Previously it fell
  # into the same else branch as "poor" and the two were indistinguishable.
  MATCH_TIER_STYLES = {
    "excellent" => {
      bar: "bg-sky-700 dark:bg-sky-300",
      bg: "bg-sky-100 dark:bg-navy-900/40",
      text: "text-sky-800 dark:text-sky-200",
      border: "border-sky-400 dark:border-sky-700"
    },
    "good" => {
      bar: "bg-sky-500 dark:bg-sky-400",
      bg: "bg-sky-50 dark:bg-navy-900/30",
      text: "text-sky-700 dark:text-sky-300",
      border: "border-sky-300 dark:border-sky-800"
    },
    "fair" => {
      bar: "bg-sky-300 dark:bg-sky-600",
      bg: "bg-sky-50 dark:bg-navy-900/20",
      text: "text-sky-600 dark:text-sky-400",
      border: "border-sky-200 dark:border-navy-700"
    },
    "poor" => {
      bar: "bg-sky-200 dark:bg-sky-700",
      bg: "bg-sky-50 dark:bg-navy-900/20",
      text: "text-sky-500 dark:text-sky-500",
      border: "border-sky-100 dark:border-navy-800"
    },
    "ineligible" => {
      bar: "bg-ink-4 dark:bg-ink-4-on-dark",
      bg: "bg-surface-2 dark:bg-navy-900/20",
      text: "text-ink-3 dark:text-ink-3-on-dark",
      border: "border-line dark:border-navy-700"
    }
  }.freeze

  DEFAULT_MATCH_TIER = "poor"

  def match_tier_styles(match_level)
    MATCH_TIER_STYLES.fetch(match_level.to_s, MATCH_TIER_STYLES.fetch(DEFAULT_MATCH_TIER))
  end

  def match_score_bg_class(match_level)
    match_tier_styles(match_level).fetch(:bg)
  end

  def match_score_border_class(match_level)
    match_tier_styles(match_level).fetch(:border)
  end

  def match_score_text_class(match_level)
    match_tier_styles(match_level).fetch(:text)
  end

  def match_score_bar_class(match_level)
    match_tier_styles(match_level).fetch(:bar)
  end

  def match_level_for(match_score)
    case match_score
    when 80..100 then "excellent"
    when 60..79 then "good"
    when 40..59 then "fair"
    else "poor"
    end
  end

  # Takes a score, so it can never produce "ineligible". A study a user is
  # barred from carries a score of 0 and will badge as "poor" here. Passing the
  # level through instead is a wider change than this recolour.
  def match_score_badge_class(match_score)
    styles = match_tier_styles(match_level_for(match_score))

    "#{styles.fetch(:bg)} #{styles.fetch(:text)} border #{styles.fetch(:border)}"
  end

  # Text formatting helper for badges and status displays
  # Converts underscored status to titleized text, or returns raw text
  def display_text(status: nil, text: nil)
    if status.present?
      status&.tr("_", " ")&.titleize
    else
      text
    end
  end
end
