class GenerateReadableStudySummaryJob < ApplicationJob
  queue_as :default

  GENERIC_ERROR_MESSAGE = "We couldn't generate a readable version right now. Please try again.".freeze

  retry_on Anthropic::Errors::RateLimitError, wait: :polynomially_longer, attempts: 5

  def perform(nct_id)
    record = ReadableStudySummary.find_or_create_pending(nct_id)
    return if record.completed?

    text = ReadableStudySummaryGenerator.new(nct_id).call
    record.update!(
      status: ReadableStudySummary::COMPLETED,
      content: text,
      error_message: nil,
      generated_at: Time.current
    )
  rescue Anthropic::Errors::RateLimitError
    raise
  rescue => e
    Rails.logger.error("Failed to generate readable study summary for #{nct_id}: #{e.class} - #{e.message}")
    record&.update(status: ReadableStudySummary::FAILED, error_message: GENERIC_ERROR_MESSAGE)
  ensure
    Turbo::StreamsChannel.broadcast_update_to(
      "readable_study_summary_#{nct_id}",
      target: "readable-study-summary-content-#{nct_id}",
      partial: "my_trials/readable_study_summary_content",
      locals: {record: record, nct_id: nct_id, source_present: true}
    )
  end
end
