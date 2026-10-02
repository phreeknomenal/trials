# Re-checks one person's saved studies against the registry, so My Trials can
# say when one stopped recruiting.
#
# Capped per run. Production runs jobs on Puma's own thread pool (:async, see
# config/environments/production.rb), and someone with eighty saved studies
# should not fire eighty registry calls from a web dyno at once. The oldest
# checks go first, so a long list catches up over a few visits.
#
# A failed lookup leaves the row stale, which retries it on the next visit. No
# retry_on: the next page load is the retry, and a registry outage should not
# stack up queued work in a process that also serves requests.
class RefreshSavedTrialsJob < ApplicationJob
  queue_as :default

  PER_RUN = 25

  def perform(user_id)
    SavedTrial.where(user_id: user_id)
      .registry_stale
      .order(Arel.sql("registry_checked_at ASC NULLS FIRST"))
      .limit(PER_RUN)
      .each { |saved_trial| refresh(saved_trial) }
  end

  private

  def refresh(saved_trial)
    study = ClinicalTrialClient.get_study(saved_trial.nct_id)

    if study.nil? || study[:error].present?
      Rails.logger.warn("Registry check skipped for #{saved_trial.nct_id}: #{study && study[:error]}")
      return
    end

    saved_trial.record_registry!(study)
  rescue => e
    Rails.logger.error("Registry check failed for #{saved_trial.nct_id}: #{e.class} - #{e.message}")
  end
end
