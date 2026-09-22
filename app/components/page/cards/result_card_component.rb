# One row of search results, in two variants that are the same card with and
# without a profile behind it.
#
# Signed in it leads with the score, because that is the question the person came
# with. Signed out there is no score at all, not a greyed-out one: a placeholder
# where a number should be reads as "we scored you badly" rather than "we have not
# met you". It leads with the study's own eligibility facts instead, and offers to
# find out.
#
# What this deliberately does not show, because the app does not have it: distance
# in miles, visit cadence, site type, and whether travel is reimbursed. The design
# boards show all four. ClinicalTrialClient returns none of them, and a card is
# not the place to start inventing.
class Page::Cards::ResultCardComponent < ApplicationComponent
  # The six criteria TrialScorer weighs. Named here so the count a card reports
  # cannot drift from what was actually scored.
  CRITERIA = %i[age sex conditions location study_type phase_risk].freeze

  # Scores come back as 0, 25, 50 or 100. 50 is the neutral default the scorer
  # uses when the profile has not answered, so it is "unknown", not "half met".
  MET = 75
  UNKNOWN = 50

  DISQUALIFIER_REASONS = {
    age: "You are outside the ages this study is recruiting.",
    sex: "This study is recruiting one sex, and it is not the one on your profile.",
    not_recruiting: "This study is not recruiting at the moment."
  }.freeze

  attr_reader :study, :saved_trial, :signed_in

  def initialize(study:, saved_trial: nil, signed_in: false)
    @study = study
    @saved_trial = saved_trial
    @signed_in = signed_in
  end

  def signed_in? = !!signed_in

  def nct_id = study[:nct_id]

  def title = study[:title]

  def detail_path = search_path(nct_id)

  # A score only exists when a profile was there to produce one, so this is the
  # single switch between the two variants.
  def scored? = signed_in? && study[:trial_score].present?

  def score = study[:trial_score]

  def match_level = study[:match_level]

  def ineligible? = match_level == TrialScorer::INELIGIBLE

  def tier_label
    return "Not eligible" if ineligible?

    "#{match_level.to_s.capitalize} match"
  end

  def breakdown = study[:score_breakdown] || {}

  def criteria_met = CRITERIA.count { |c| breakdown[c].to_i >= MET }

  def criteria_unknown = CRITERIA.count { |c| breakdown[c].to_i == UNKNOWN }

  # Says what is known and what is missing, rather than rounding the unknowns
  # into either column. "Meets 3 of 6" when two were never answered is a claim
  # the profile does not support.
  def criteria_summary
    return nil unless scored? && breakdown.any?

    summary = "Meets #{criteria_met} of #{CRITERIA.length} checks"
    return summary if criteria_unknown.zero?

    "#{summary} · #{criteria_unknown} need more of your profile"
  end

  def disqualifier_reason
    reasons = Array(study[:disqualifiers]).filter_map { |d| DISQUALIFIER_REASONS[d.to_sym] }

    reasons.presence&.join(" ")
  end

  # Phase and recruitment status are the study's own facts, so they show in both
  # variants and are the whole eyebrow when signed out.
  def eyebrow
    [study[:phase].presence, recruiting_label].compact.join(" · ")
  end

  def recruiting_label
    return nil if study[:status].blank?

    study[:status].to_s.tr("_", " ").downcase.capitalize
  end

  def conditions = Array(study[:conditions]).first(2)

  # There is no distance in the data. locations_detailed carries a near_you
  # boolean derived from matching city and state strings, nothing more, so this
  # says "Near you" and never a number of miles.
  def location_label
    detailed = Array(study[:locations_detailed]).first
    return Array(study[:locations]).first if detailed.blank?

    detailed[:display]
  end

  def near_you?
    return false unless signed_in?

    Array(study[:locations_detailed]).any? { |l| l[:near_you] }
  end

  def age_range
    low, high = study[:min_age].presence, study[:max_age].presence
    return nil if low.blank? && high.blank?
    return "Ages #{low} and over" if high.blank?
    return "Ages #{high} and under" if low.blank?

    "Ages #{low} to #{high}"
  end

  def card_class
    base = "bg-surface dark:bg-surface-on-dark border rounded-card p-5 transition-colors"

    if ineligible?
      "#{base} border-line dark:border-line-on-dark opacity-75"
    else
      "#{base} border-line dark:border-line-on-dark hover:border-navy-600 dark:hover:border-sky-400"
    end
  end

  def score_class = match_score_badge_class(score)
end
