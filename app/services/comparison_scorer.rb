# Scores saved trials for the comparison page, against the same study data the
# results page scores against.
#
# The comparison used to build its own trial hash out of the saved columns and
# pass `conditions: []`, `locations: []`, `sex: nil` to TrialScorer, because
# saved_trials stores none of those. Conditions and location are 40 of the 100
# points between them, so both fell to their neutral defaults and the same study
# showed one number on the results page and a different one here — with a
# breakdown that then highlighted a "winner" among meaningless values.
#
# So it fetches the study. Comparison is capped at three trials, so this is at
# most three requests, and the detail page already makes one.
class ComparisonScorer
  # Long enough for three sequential fetches, short enough that a slow registry
  # does not hold the page indefinitely. TrialRecommendationService uses the same
  # five seconds for one request; this is per request, not for the batch.
  REQUEST_TIMEOUT = 5

  Scored = Data.define(:saved_trial, :breakdown, :total, :match_level, :stale) do
    # True when the registry could not be reached for this one. The page says so
    # rather than showing a score it cannot stand behind.
    def stale? = stale
  end

  def initialize(profile:, saved_trials:)
    @profile = profile
    @saved_trials = saved_trials
  end

  def call
    @saved_trials.map { |saved_trial| score(saved_trial) }
  end

  private

  def score(saved_trial)
    study = fetch(saved_trial.nct_id)

    if study.blank? || study[:error].present?
      return Scored.new(saved_trial: saved_trial, breakdown: nil, total: saved_trial.match_score,
        match_level: saved_trial.match_level, stale: true)
    end

    result = TrialScorer.new(@profile, study).calculate_score

    return Scored.new(saved_trial: saved_trial, breakdown: nil, total: nil, match_level: nil, stale: false) if result.blank?

    Scored.new(saved_trial: saved_trial, breakdown: result[:breakdown], total: result[:total],
      match_level: result[:match_level], stale: false)
  end

  # Rescued rather than raised: one unreachable study should cost that row its
  # breakdown, not the whole page.
  def fetch(nct_id)
    Timeout.timeout(REQUEST_TIMEOUT) { ClinicalTrialClient.get_study(nct_id) }
  rescue => e
    Rails.logger.error("Comparison could not fetch #{nct_id}: #{e.class} - #{e.message}")
    nil
  end
end
