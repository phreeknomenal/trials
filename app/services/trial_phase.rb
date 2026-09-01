# Shared vocabulary for ClinicalTrials.gov phase values.
#
# ClinicalTrialClient passes the v2 enum through untouched:
#
#   phase: design.dig("phases")&.join(", ")
#
# which yields "PHASE4", "PHASE2, PHASE3", "EARLY_PHASE1", "NA", or nil. Three
# places each carried their own idea of that format and two of them were wrong:
# TrialScorer tested include?("phase 4") and MatchScoreCardComponent tested
# include?("Phase 4"), neither of which can ever match "PHASE4". Every real
# phase string scored 0, so stating a risk tolerance was strictly worse than
# leaving it blank.
#
# Same fix as TrialStatus: one normalised vocabulary, matched exactly.
module TrialPhase
  EARLY_PHASE1 = "early_phase1"
  PHASE1 = "phase1"
  PHASE2 = "phase2"
  PHASE3 = "phase3"
  PHASE4 = "phase4"

  # The registry's marker for a study with no FDA phase. Common for behavioural,
  # device, and observational studies. Not a phase, and deliberately not part of
  # ORDER, because it is not "less tested than Phase 1" -- it is a different
  # kind of study that administers no investigational drug at all.
  NOT_APPLICABLE = "na"

  # Ordered by how much prior human testing has happened.
  ORDER = [EARLY_PHASE1, PHASE1, PHASE2, PHASE3, PHASE4].freeze

  LABELS = {
    EARLY_PHASE1 => "Early Phase 1",
    PHASE1 => "Phase 1",
    PHASE2 => "Phase 2",
    PHASE3 => "Phase 3",
    PHASE4 => "Phase 4",
    NOT_APPLICABLE => "Not Applicable"
  }.freeze

  module_function

  # "PHASE2, PHASE3" is one seamless trial spanning both, so this returns every
  # phase it names rather than collapsing to one.
  def levels(value)
    value.to_s.downcase.split(",")
      .map { |part| part.strip.gsub(/[\s-]+/, "_") }
      .reject(&:empty?)
  end

  def blank?(value)
    levels(value).empty?
  end

  def not_applicable?(value)
    levels(value).include?(NOT_APPLICABLE)
  end

  # The least-tested phase named, which is the honest risk signal for a trial
  # spanning several. Someone enrolling in a PHASE1, PHASE2 study is exposed to
  # phase 1 risk regardless of what the trial goes on to measure, so reporting
  # the highest would understate what they are agreeing to.
  #
  # nil when nothing recognisable is named, including for NA.
  def lowest(value)
    named = levels(value) & ORDER
    ORDER.find { |phase| named.include?(phase) }
  end

  # True when the trial has been through at least `minimum` phases of testing.
  # NA is never "at least" anything, because it is not on the scale.
  def at_least?(value, minimum)
    current = lowest(value)
    return false if current.nil?

    ORDER.index(current) >= ORDER.index(minimum)
  end

  # Human-readable, for display. "PHASE2, PHASE3" reads as "Phase 2/3".
  # Returns nil rather than a placeholder so callers decide how to render
  # a trial that names no phase.
  def label(value)
    known = levels(value).filter_map { |phase| LABELS[phase] }
    return nil if known.empty?
    return known.first if known.one?

    # "Phase 2", "Phase 3" -> "Phase 2/3"
    numbers = known.filter_map { |name| name[/\d+\z/] }
    return known.join(", ") unless numbers.length == known.length

    "Phase #{numbers.join("/")}"
  end
end
