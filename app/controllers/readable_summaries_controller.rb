# Public. Generating a plain-language summary is a paid Claude call per distinct
# nct_id, and nct ids are publicly enumerable across roughly 500,000 studies, so
# the thing standing between this endpoint and a large Anthropic bill used to be
# authentication. Opening it to signed-out visitors replaces that with explicit
# limits.
#
# Three of them, because each covers a case the others do not:
#
#   - per IP, which stops one anonymous visitor walking the registry
#   - per user, more generous, because a signed-in person is attributable
#   - a global daily cap, the only one that helps against many IPs at once
class ReadableSummariesController < ApplicationController
  ANONYMOUS_HOURLY_LIMIT = 5
  SIGNED_IN_HOURLY_LIMIT = 30

  def self.daily_limit
    Integer(ENV.fetch("READABLE_SUMMARY_DAILY_LIMIT", 200))
  end

  rate_limit to: ANONYMOUS_HOURLY_LIMIT, within: 1.hour,
    name: "anonymous",
    by: -> { request.remote_ip },
    with: -> { reject_rate_limited },
    if: -> { !user_signed_in? }

  rate_limit to: SIGNED_IN_HOURLY_LIMIT, within: 1.hour,
    name: "signed_in",
    by: -> { current_user.id },
    with: -> { reject_rate_limited },
    if: -> { user_signed_in? }

  before_action :reject_invalid_nct_id
  before_action :reject_when_daily_cap_reached

  def create
    record = ReadableStudySummary.find_or_create_pending(nct_id)
    enqueue(record)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: summary_stream(record.reload) }
      format.html { redirect_back fallback_location: search_path(nct_id) }
    end
  end

  private

  def nct_id
    params[:nct_id]
  end

  def summary_stream(record, source_present: true)
    turbo_stream.update(
      "readable-study-summary-content-#{nct_id}",
      partial: "shared/readable_study_summary_content",
      locals: {record: record, nct_id: nct_id, source_present: source_present}
    )
  end

  def reject_invalid_nct_id
    return if nct_id.to_s.match?(ReadableStudySummary::NCT_ID_FORMAT)

    respond_to do |format|
      format.turbo_stream { head :unprocessable_entity }
      format.html { redirect_back fallback_location: search_index_path, alert: "That is not a valid study id." }
    end
  end

  # Counts records created, which is exactly the number of paid calls made,
  # rather than requests received. A repeat request for a study that already has
  # a summary costs nothing and is not counted.
  def reject_when_daily_cap_reached
    return if ReadableStudySummary.where(created_at: 24.hours.ago..).count < self.class.daily_limit
    return if ReadableStudySummary.exists?(nct_id: nct_id)

    respond_with_limit_message(
      "We have generated as many summaries as we can today. Please try again tomorrow."
    )
  end

  def reject_rate_limited
    respond_with_limit_message(
      "That is a few too many summaries in a short time. Please wait a little while and try again."
    )
  end

  def respond_with_limit_message(message)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "readable-study-summary-content-#{nct_id}",
          partial: "shared/readable_summary_limited",
          locals: {message: message}
        ), status: :too_many_requests
      end
      format.html { redirect_back fallback_location: search_index_path, alert: message }
    end
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
