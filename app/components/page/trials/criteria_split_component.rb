# The payoff for the score on the result row: which criteria you actually meet,
# which the study team still has to check, and which rule you out.
#
# EligibilityChecker already produces all of it. The old checklist rendered the
# items as one flat list, so "your age fits" and "your age rules you out" sat
# together with nothing but an icon colour between them, and a reader had to sort
# the list themselves to answer the only question they came with.
#
# Three groups rather than the two on the design board, because a hard failure is
# not the same as something the team will confirm, and folding them together
# would make an ineligible study look like a maybe.
class Page::Trials::CriteriaSplitComponent < ApplicationComponent
  GROUPS = {
    met: {
      heading: "What you meet",
      note: "From the answers on your profile.",
      icon: "check_circle",
      tone: "text-good dark:text-good-on-dark"
    },
    checking: {
      heading: "What the study team still checks",
      note: "Your profile cannot answer these. They are settled at the screening visit.",
      icon: "question_circle",
      tone: "text-ink-3 dark:text-ink-3-on-dark"
    },
    blocking: {
      heading: "What rules you out",
      note: "These are the study's own limits, not something to fix on your profile.",
      icon: "close_circle",
      tone: "text-crit dark:text-crit-on-dark"
    }
  }.freeze

  STATUS_GROUP = {
    "met" => :met,
    "not_met" => :blocking,
    "warning" => :checking,
    "unknown" => :checking,
    "info" => :checking
  }.freeze

  attr_reader :checklist, :profile

  # The score comes in here now rather than sitting in a panel of its own.
  # The board draws one match panel headed "You meet 6 of 7 criteria", with the
  # number beside it; the app had the number and its per-factor breakdown in one
  # section and the criteria in another, two panels apart, so the score and the
  # reason for it were never on screen together.
  def initialize(checklist:, profile: nil, trial_score: nil, match_level: nil, score_breakdown: nil)
    @checklist = Array(checklist)
    @profile = profile
    @trial_score = trial_score
    @match_level = match_level
    @score_breakdown = score_breakdown
  end

  attr_reader :trial_score, :match_level, :score_breakdown

  def score? = trial_score.present?

  def breakdown? = score_breakdown.present?

  # What the score is made of, out of TrialScorer's own breakdown. Behind a
  # disclosure because the criteria are the answer and this is the working.
  def breakdown_items
    return [] unless breakdown?

    [
      {label: "Age", value: score_breakdown[:age], icon: "calendar_month"},
      {label: "Sex", value: score_breakdown[:sex], icon: "user"},
      {label: "Conditions", value: score_breakdown[:conditions], icon: "microscope"},
      {label: "Location", value: score_breakdown[:location], icon: "map_pin"},
      {label: "Study type", value: score_breakdown[:study_type], icon: "rectangle_stack"},
      {label: "Risk level", value: score_breakdown[:phase_risk], icon: "exclamation_triangle"}
    ].select { |item| item[:value].present? }
  end

  def render? = checklist.any?

  def grouped
    @grouped ||= checklist.group_by { |item| STATUS_GROUP.fetch(item[:status].to_s, :checking) }
  end

  # Empty groups are left out rather than rendered with a reassuring zero. A
  # "What rules you out" heading with nothing under it invites a second read.
  def visible_groups
    GROUPS.filter_map { |key, config| [key, config, grouped[key]] if grouped[key].present? }
  end

  def met_count = grouped[:met]&.length.to_i

  def total_count = checklist.length

  # Stated rather than implied, because a number scored against a profile is
  # only as current as the profile. The link is the useful half of the caveat.
  def profile_updated_on
    profile&.updated_at&.to_date&.to_fs(:long)
  end
end
