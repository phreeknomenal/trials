# Where you are with a saved study, and the control for changing it.
#
# Status used to live in the edit form, behind a Save. The board moves it here
# because changing status is the thing people open this page to do: you ring the
# coordinator, they say they will send a packet, and you want to mark it
# contacted without filling in a form about your notes.
#
# Four of the seven statuses are a pipeline, so they are drawn as one. The other
# three are terminal and outside it: rejected is somebody else's decision,
# completed is the study ending, not eligible is a criterion you cannot change.
# Putting them on the same line would imply you progress into them.
class Page::SavedTrials::PipelineComponent < ApplicationComponent
  # The order somebody actually moves through. SavedTrial::STATUSES has all
  # seven in its own order; this is the four that are a sequence.
  STEPS = %w[interested applying contacted enrolled].freeze

  TERMINAL = (SavedTrial::STATUSES - STEPS).freeze

  attr_reader :saved_trial

  def initialize(saved_trial:)
    @saved_trial = saved_trial
  end

  def current = saved_trial.status.to_s

  # A terminal study has left the pipeline, so nothing on it is "reached".
  def terminal? = TERMINAL.include?(current)

  def current_index = STEPS.index(current)

  def reached?(step)
    return false if terminal?

    index = STEPS.index(step)
    current_index.present? && index <= current_index
  end

  def active?(step) = !terminal? && step == current

  def label_for(step) = Shared::StatusBadgeComponent::STATUSES.dig(step, :label) || step.humanize

  # The one step forward, offered as a button because it is what happens next
  # nine times out of ten. Everything else is in the select beside it.
  def next_step
    return nil if terminal? || current_index.nil?

    STEPS[current_index + 1]
  end

  def other_statuses
    SavedTrial::STATUSES - [current, next_step].compact
  end

  def step_circle_class(step)
    if active?(step)
      "bg-sky-500 dark:bg-sky-400 ring-4 ring-sky-100 dark:ring-navy-900"
    elsif reached?(step)
      "bg-navy-600 dark:bg-sky-300"
    else
      "border-2 border-dashed border-line-2 dark:border-line-2-on-dark"
    end
  end

  def step_label_class(step)
    if active?(step)
      "font-extrabold text-sky-700 dark:text-sky-300"
    elsif reached?(step)
      "font-bold text-ink dark:text-ink-on-dark"
    else
      "font-semibold text-ink-3 dark:text-ink-3-on-dark"
    end
  end

  def connector_class(step)
    reached?(step) ? "bg-navy-600 dark:bg-sky-300" : "bg-line dark:bg-line-on-dark"
  end
end
