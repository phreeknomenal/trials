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
# would make an ineligible study look like a maybe. The board's two sit side by
# side as columns; the third runs full width underneath, where it cannot be
# mistaken for one half of a pair.
class Page::Trials::CriteriaSplitComponent < ApplicationComponent
  GROUPS = {
    met: {
      heading: "What you meet",
      # No note. The line under the heading already says these were checked
      # against the profile, and repeating it here was the same sentence twice.
      note: nil
    },
    checking: {
      heading: "What the team still checks",
      note: "Your profile cannot answer these. They are settled at the screening visit."
    },
    blocking: {
      heading: "What rules you out",
      note: "These are the study's own limits, not something to fix on your profile."
    }
  }.freeze

  # The two the board draws as columns, and the one it does not draw at all.
  COLUMNS = %i[met checking].freeze

  STATUS_GROUP = {
    "met" => :met,
    "not_met" => :blocking,
    "warning" => :checking,
    "unknown" => :checking,
    "info" => :checking
  }.freeze

  # Marked per item rather than per group, which is what the board does: its
  # right-hand column carries an amber (i) on the two criteria the team will
  # actually verify and a grey (!) on the one that is merely unknown. Those are
  # different statuses in EligibilityChecker already, and the group was flattening
  # them into one icon.
  ITEM_MARKS = {
    "met" => ["check", "text-good dark:text-good-on-dark"],
    "not_met" => ["close_circle", "text-crit dark:text-crit-on-dark"],
    "warning" => ["info_circle", "text-warn dark:text-warn-on-dark"],
    "unknown" => ["exclamation_circle", "text-ink-3 dark:text-ink-3-on-dark"],
    "info" => ["info_circle", "text-ink-3 dark:text-ink-3-on-dark"]
  }.freeze

  DEFAULT_MARK = ITEM_MARKS.fetch("unknown")

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

  def mark_for(item)
    ITEM_MARKS.fetch(item[:status].to_s, DEFAULT_MARK)
  end

  # Empty groups are left out rather than rendered with a reassuring zero. A
  # "What rules you out" heading with nothing under it invites a second read.
  def column_groups = visible(COLUMNS)

  def full_width_groups = visible(GROUPS.keys - COLUMNS)

  def sections = column_groups + full_width_groups

  def full_width?(key) = COLUMNS.exclude?(key)

  def met_count = grouped[:met]&.length.to_i

  def total_count = checklist.length

  # Stated rather than implied, because a number scored against a profile is
  # only as current as the profile. The board turns the fix into a button rather
  # than a link inside the caveat, which is the right weight: it is the one
  # action this panel asks for.
  def profile_updated_on
    profile&.updated_at&.to_date&.to_fs(:long)
  end

  private

  def visible(keys)
    keys.filter_map { |key| [key, GROUPS.fetch(key), grouped[key]] if grouped[key].present? }
  end
end
