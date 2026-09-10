require "rails_helper"

# The test cache is a real memory store rather than :null_store, precisely so
# these limits can be exercised. See config/environments/test.rb.
RSpec.describe "Readable summary limits", type: :request do
  let(:turbo_headers) { {"Accept" => "text/vnd.turbo-stream.html"} }

  def generate(nct_id)
    post readable_summary_path(nct_id), headers: turbo_headers
  end

  def nct(n) = format("NCT%08d", n)

  describe "the per-IP hourly limit for anonymous visitors" do
    it "allows up to the limit" do
      ReadableSummariesController::ANONYMOUS_HOURLY_LIMIT.times { |i| generate(nct(i)) }

      expect(response).to have_http_status(:ok)
    end

    it "refuses the one after that" do
      (ReadableSummariesController::ANONYMOUS_HOURLY_LIMIT + 1).times { |i| generate(nct(i)) }

      expect(response).to have_http_status(:too_many_requests)
    end

    it "says what happened rather than failing silently" do
      (ReadableSummariesController::ANONYMOUS_HOURLY_LIMIT + 1).times { |i| generate(nct(i)) }

      expect(response.body).to include("too many summaries in a short time")
    end

    it "creates no record once refused" do
      ReadableSummariesController::ANONYMOUS_HOURLY_LIMIT.times { |i| generate(nct(i)) }

      expect { generate(nct(99)) }.not_to change(ReadableStudySummary, :count)
    end

    it "enqueues no paid job once refused" do
      ReadableSummariesController::ANONYMOUS_HOURLY_LIMIT.times { |i| generate(nct(i)) }

      expect { generate(nct(99)) }.not_to have_enqueued_job(GenerateReadableStudySummaryJob)
    end
  end

  describe "signed-in visitors" do
    before { sign_in create(:user) }

    it "get a higher limit than anonymous ones" do
      expect(ReadableSummariesController::SIGNED_IN_HOURLY_LIMIT)
        .to be > ReadableSummariesController::ANONYMOUS_HOURLY_LIMIT
    end

    it "are not stopped at the anonymous limit" do
      (ReadableSummariesController::ANONYMOUS_HOURLY_LIMIT + 1).times { |i| generate(nct(i)) }

      expect(response).to have_http_status(:ok)
    end
  end

  # The per-IP and per-user limits do nothing against many IPs at once. This is
  # the only one that caps the worst-case bill.
  describe "the global daily cap" do
    before { allow(ReadableSummariesController).to receive(:daily_limit).and_return(2) }

    it "refuses a new study once the cap is reached" do
      2.times { |i| ReadableStudySummary.create!(nct_id: nct(i), status: "completed") }

      generate(nct(50))

      expect(response).to have_http_status(:too_many_requests)
    end

    it "explains that the cap is daily" do
      2.times { |i| ReadableStudySummary.create!(nct_id: nct(i), status: "completed") }

      generate(nct(50))

      expect(response.body).to include("as many summaries as we can today")
    end

    # A study that already has a summary costs nothing, so the cap must not
    # block re-requesting one.
    it "still serves a study that already has a summary" do
      2.times { |i| ReadableStudySummary.create!(nct_id: nct(i), status: "completed") }

      generate(nct(0))

      expect(response).to have_http_status(:ok)
    end

    it "counts only the last 24 hours" do
      2.times do |i|
        ReadableStudySummary.create!(nct_id: nct(i), status: "completed", created_at: 3.days.ago)
      end

      generate(nct(50))

      expect(response).to have_http_status(:ok)
    end
  end
end
