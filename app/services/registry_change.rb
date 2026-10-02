# What moved on the registry since the person last looked at a saved study.
#
# One change per study, the one that matters most. A study that stops
# recruiting also gets a newer update date, and "updated" would bury the news,
# so status comes first.
#
# "Stopped" is measured against TrialStatus::ACCEPTING, not CLOSED. Recruiting
# to active-not-recruiting closes the door on a new participant just as surely
# as completed does, and CLOSED does not include it.
class RegistryChange
  KINDS = {
    stopped: {label: "No longer recruiting", icon: "exclamation_triangle", tone: :warn},
    started: {label: "Now recruiting", icon: "check_circle", tone: :good},
    status: {label: "Status changed", icon: "info_circle", tone: :info},
    updated: {label: "Updated since you last looked", icon: "clock_arrow", tone: :neutral}
  }.freeze

  attr_reader :kind, :saved_trial

  def self.for(saved_trial)
    kind = kind_for(saved_trial)
    new(kind: kind, saved_trial: saved_trial) if kind
  end

  def self.kind_for(saved_trial)
    return nil unless saved_trial.registry_checked_at

    from = saved_trial.trial_status
    to = saved_trial.registry_status

    if from.present? && to.present? && TrialStatus.normalize(from) != TrialStatus.normalize(to)
      return :stopped if TrialStatus.accepting?(from) && !TrialStatus.accepting?(to)
      return :started if !TrialStatus.accepting?(from) && TrialStatus.accepting?(to)

      return :status
    end

    seen = saved_trial.seen_last_update
    latest = saved_trial.registry_last_update
    :updated if seen && latest && latest > seen
  end

  def initialize(kind:, saved_trial:)
    @kind = kind
    @saved_trial = saved_trial
  end

  def label = KINDS.fetch(kind)[:label]

  def icon = KINDS.fetch(kind)[:icon]

  def tone = KINDS.fetch(kind)[:tone]

  def status_change? = kind != :updated

  # The registry records that a study was edited, never what was edited, so the
  # updated case says so instead of guessing.
  def explanation
    if status_change?
      "It was listed as #{status_label(saved_trial.trial_status)} when you last looked. " \
        "The registry now lists it as #{status_label(saved_trial.registry_status)}."
    else
      "The study team edited its registry record on #{saved_trial.registry_last_update.to_fs(:long)}. " \
        "The registry does not say what changed, so the full study is the place to check."
    end
  end

  # Only when the study actually stopped. A why_stopped left over from an
  # earlier suspension would be wrong under "Now recruiting".
  def why_stopped
    saved_trial.registry_why_stopped.presence if kind == :stopped
  end

  private

  def status_label(value) = TrialStatus.label(value).to_s.downcase
end
