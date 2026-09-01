# Recomputes persisted match_score values on saved trials.
#
# SavedTrial#match_score is written once when a trial is saved and then used for
# sorting. Any change to TrialScorer leaves existing rows holding a score from
# the old algorithm, sorted against rows scored by the new one. Mixing vintages
# silently is the one outcome clearly worth avoiding.
#
# Each row needs a fresh API lookup, so this is deliberately a batch task rather
# than something that runs inline.
class SavedTrialRescorer
  Result = Struct.new(:rescored, :skipped, :failed, :errors)

  def initialize(dry_run: false, logger: nil)
    @dry_run = dry_run
    @logger = logger
  end

  def call(scope = SavedTrial.all)
    result = Result.new(rescored: 0, skipped: 0, failed: 0, errors: [])

    scope.includes(user: :profile).find_each do |saved_trial|
      profile = saved_trial.user&.profile

      if profile.nil?
        result.skipped += 1
        log "skip #{saved_trial.nct_id}: no profile"
        next
      end

      rescore(saved_trial, profile, result)
    end

    result
  end

  private

  def rescore(saved_trial, profile, result)
    study = ClinicalTrialClient.get_study(saved_trial.nct_id)

    if study.nil? || study[:error].present?
      result.failed += 1
      result.errors << "#{saved_trial.nct_id}: #{study && study[:error]}"
      log "fail #{saved_trial.nct_id}: #{study && study[:error]}"
      return
    end

    score = TrialScorer.new(profile, study).calculate_score
    was = saved_trial.match_score

    saved_trial.update_column(:match_score, score[:total]) unless @dry_run

    result.rescored += 1
    log "#{@dry_run ? "would set" : "set"} #{saved_trial.nct_id}: #{was.inspect} -> #{score[:total]}#{" (ineligible)" unless score[:eligible]}"
  rescue => e
    result.failed += 1
    result.errors << "#{saved_trial.nct_id}: #{e.class}: #{e.message}"
    log "fail #{saved_trial.nct_id}: #{e.class}: #{e.message}"
  end

  def log(message)
    @logger&.call(message)
  end
end
