# Shared vocabulary for ClinicalTrials.gov overall status values.
#
# Both TrialScorer and EligibilityChecker read trial status, and before this
# they each carried their own list. One source means the score and the
# eligibility checklist cannot drift into disagreeing about whether a trial is
# open.
#
# Matching is exact against a normalised form rather than substring, because
# substrings are actively wrong here: "ACTIVE_NOT_RECRUITING" contains
# "RECRUITING", and "NOT_YET_RECRUITING" does too.
module TrialStatus
  # Definitively closed. Nobody can enrol, so these disqualify.
  CLOSED = %w[completed terminated withdrawn suspended].freeze

  # Open to new participants now.
  OPEN = %w[recruiting enrolling_by_invitation].freeze

  # Running or planned, but not enrolling today. Not a disqualifier -- a trial
  # that has not opened yet is a legitimate future option, and one that is
  # active can reopen.
  PENDING = %w[not_yet_recruiting active_not_recruiting].freeze

  module_function

  def normalize(value)
    value.to_s.downcase.strip.gsub(/[\s,]+/, "_")
  end

  def closed?(value)
    CLOSED.include?(normalize(value))
  end

  def open?(value)
    OPEN.include?(normalize(value))
  end

  def pending?(value)
    PENDING.include?(normalize(value))
  end

  # An unrecognised or missing status is not treated as closed. The registry
  # uses UNKNOWN widely, and guessing would hide trials that may be open.
  def known?(value)
    closed?(value) || open?(value) || pending?(value)
  end
end
