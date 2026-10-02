# The limits in front of any endpoint that makes a paid Claude call per
# distinct nct_id. nct ids are publicly enumerable across roughly 500,000
# studies, so without these one visitor could walk the registry on our bill.
#
# Three of them, because each covers a case the others do not:
#
#   - per IP, which stops one anonymous visitor walking the registry
#   - per user, more generous, because a signed-in person is attributable
#   - a global daily cap, the only one that helps against many IPs at once
#
# rate_limit keys its counters by controller, so each feature that includes
# this gets its own hourly budget. Spending summaries does not spend questions.
#
# The including controller supplies:
#
#   paid_record_class   the model that holds one generated row per nct_id
#   limit_target_id     the DOM id the refusal message replaces
#   limit_noun          "summaries", "questions", for the refusal messages
#   self.daily_limit    the rolling 24 hour cap on new rows
module PaidGenerationLimits
  extend ActiveSupport::Concern

  class_methods do
    def limits_paid_generation(anonymous_per_hour:, signed_in_per_hour:)
      rate_limit to: anonymous_per_hour, within: 1.hour,
        name: "anonymous",
        by: -> { request.remote_ip },
        with: -> { reject_rate_limited },
        if: -> { !user_signed_in? }

      rate_limit to: signed_in_per_hour, within: 1.hour,
        name: "signed_in",
        by: -> { current_user.id },
        with: -> { reject_rate_limited },
        if: -> { user_signed_in? }

      before_action :reject_invalid_nct_id
      before_action :reject_when_daily_cap_reached
    end
  end

  private

  def nct_id
    params[:nct_id]
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
  # a row costs nothing and is not counted.
  def reject_when_daily_cap_reached
    return if paid_record_class.where(created_at: 24.hours.ago..).count < self.class.daily_limit
    return if paid_record_class.exists?(nct_id: nct_id)

    respond_with_limit_message(
      "We have generated as many #{limit_noun} as we can today. Please try again tomorrow."
    )
  end

  def reject_rate_limited
    respond_with_limit_message(
      "That is a few too many #{limit_noun} in a short time. Please wait a little while and try again."
    )
  end

  def respond_with_limit_message(message)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          limit_target_id,
          partial: "shared/generation_limited",
          locals: {message: message}
        ), status: :too_many_requests
      end
      format.html { redirect_back fallback_location: search_index_path, alert: message }
    end
  end
end
