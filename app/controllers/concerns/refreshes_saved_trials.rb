# Queues a registry check when a page that lists saved studies loads.
#
# Checked on read rather than on a schedule, since a saved study nobody opens
# needs no check, and the badge only ever appears on these pages. The page
# itself renders from what is already stored. The check lands for the next load.
module RefreshesSavedTrials
  extend ActiveSupport::Concern

  private

  def refresh_saved_trials_later
    return unless current_user.saved_trials.registry_stale.exists?

    RefreshSavedTrialsJob.perform_later(current_user.id)
  end
end
