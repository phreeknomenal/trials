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

  # What a search asks the registry for.
  #
  # This module already knew which statuses mean a person can act on a study.
  # Nothing ever told the registry. `advanced_search` sent a condition and a
  # location and no status at all, so a search returned whatever the registry
  # held: across asthma, leukemia, diabetes and migraine, between 6% and 14% of
  # the first hundred results were recruiting and most of the rest were
  # completed. The app was scoring, ranking and recommending studies nobody
  # could enrol in.
  #
  # `active_not_recruiting` is in PENDING but deliberately not here. The two
  # lists answer different questions: PENDING asks "should this count against
  # the study", and the answer is no, a study can reopen. This asks "can the
  # person do anything about it today", and for a study that is running with
  # enrolment closed the answer is no.
  #
  # `available` is the registry's expanded-access value and has no place in the
  # other three lists, because it never reaches a scorer. It belongs here: it is
  # a real route to a treatment.
  ACCEPTING = %w[recruiting not_yet_recruiting enrolling_by_invitation available].freeze

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

  def accepting?(value)
    ACCEPTING.include?(normalize(value))
  end

  # The registry's own spelling is an enum, NOT_YET_RECRUITING. Dropped into a
  # sentence for a patient to read it shouts in a vocabulary they did not ask
  # for, which is how it reached the eligibility checklist.
  def label(value)
    normalized = normalize(value)
    return nil if normalized.blank?

    normalized.tr("_", " ").upcase_first
  end

  # The value for `filter.overallStatus`. The API ORs pipe-separated values, and
  # wants the registry's own shouted spelling.
  def registry_filter
    ACCEPTING.map(&:upcase).join("|")
  end
end
