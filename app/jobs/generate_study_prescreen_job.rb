class GenerateStudyPrescreenJob < ApplicationJob
  queue_as :default

  GENERIC_ERROR_MESSAGE = "We couldn't write questions for this study right now. Please try again.".freeze

  retry_on Anthropic::Errors::RateLimitError, wait: :polynomially_longer, attempts: 5

  def perform(nct_id)
    record = StudyPrescreen.find_or_create_pending(nct_id)
    return if record.completed?

    result = StudyPrescreenGenerator.new(nct_id).call
    record.update!(
      status: StudyPrescreen::COMPLETED,
      questions: result.questions,
      criteria_digest: result.criteria_digest,
      error_message: nil,
      generated_at: Time.current
    )
  rescue Anthropic::Errors::RateLimitError
    raise
  rescue => e
    Rails.logger.error("Failed to generate prescreen for #{nct_id}: #{e.class} - #{e.message}")
    record&.update(status: StudyPrescreen::FAILED, error_message: GENERIC_ERROR_MESSAGE)
  ensure
    # A refresh rather than a rendered partial. The panel depends on who is
    # looking, whether they are signed in and what they have answered, and a
    # broadcast has no current_user. Each open page refetches itself instead.
    Turbo::StreamsChannel.broadcast_refresh_to("study_prescreen_#{nct_id}")
  end
end
