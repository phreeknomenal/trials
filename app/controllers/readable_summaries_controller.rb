# Public. Generating a plain-language summary is a paid Claude call per distinct
# nct_id, so opening it to signed-out visitors put explicit limits in place of
# authentication. See PaidGenerationLimits.
class ReadableSummariesController < ApplicationController
  include PaidGenerationLimits

  ANONYMOUS_HOURLY_LIMIT = 5
  SIGNED_IN_HOURLY_LIMIT = 30

  def self.daily_limit
    Integer(ENV.fetch("READABLE_SUMMARY_DAILY_LIMIT", 200))
  end

  limits_paid_generation anonymous_per_hour: ANONYMOUS_HOURLY_LIMIT,
    signed_in_per_hour: SIGNED_IN_HOURLY_LIMIT

  def create
    record = ReadableStudySummary.find_or_create_pending(nct_id)
    enqueue(record)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: summary_stream(record.reload) }
      format.html { redirect_back fallback_location: search_path(nct_id) }
    end
  end

  private

  def paid_record_class = ReadableStudySummary

  def limit_target_id = "readable-study-summary-content-#{nct_id}"

  def limit_noun = "summaries"

  def summary_stream(record, source_present: true)
    turbo_stream.update(
      "readable-study-summary-content-#{nct_id}",
      partial: "shared/readable_study_summary_content",
      locals: {record: record, nct_id: nct_id, source_present: source_present}
    )
  end

  def enqueue(record)
    just_created = record.previously_new_record?

    should_enqueue =
      if record.completed?
        false
      elsif record.failed?
        record.update!(status: ReadableStudySummary::PENDING, error_message: nil)
        true
      elsif just_created
        true
      elsif record.stale?
        record.touch
        true
      else
        false
      end

    GenerateReadableStudySummaryJob.perform_later(nct_id) if should_enqueue
  end
end
