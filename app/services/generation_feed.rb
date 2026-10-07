# One queue of paid, per-study Claude generation, as the admin pages report it.
#
# Both queues share GeneratedPerStudy, so they share the same health questions:
# what failed, what is stuck, what is running. Listing them here means a third
# paid feature shows up on operations and the dashboard by adding one entry.
class GenerationFeed
  attr_reader :title, :noun, :model, :retry_route, :failure_note

  def self.all
    [
      new(
        title: "Readable summaries",
        noun: "summary",
        model: ReadableStudySummary,
        retry_route: :readable_summary_path,
        failure_note: "Retrying a study whose registry record has no summary text will fail again."
      ),
      new(
        title: "Prescreen questions",
        noun: "question set",
        model: StudyPrescreen,
        retry_route: :study_prescreen_path,
        failure_note: "Retrying a study that lists no eligibility criteria will fail again."
      )
    ]
  end

  def initialize(title:, noun:, model:, retry_route:, failure_note:)
    @title = title
    @noun = noun
    @model = model
    @retry_route = retry_route
    @failure_note = failure_note
  end

  def failed = @failed ||= model.failed.recent_first.to_a

  def stale = @stale ||= model.stale.recent_first.to_a

  def pending
    @pending ||= model.pending.where.not(id: model.stale.select(:id)).recent_first.to_a
  end

  def completed_count = @completed_count ||= model.completed.count

  def healthy? = failed.none? && stale.none?

  def dom_id = "#{model.model_name.param_key}-feed"
end
