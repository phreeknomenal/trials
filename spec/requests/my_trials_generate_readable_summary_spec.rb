require "rails_helper"

RSpec.describe "POST /my_trials/:id/generate_readable_summary", type: :request do
  let(:user) { create(:user) }
  let(:nct_id) { "NCT01234567" }
  let(:turbo_headers) { {"Accept" => "text/vnd.turbo-stream.html"} }

  def post_generate
    post generate_readable_summary_my_trial_path(nct_id), headers: turbo_headers
  end

  context "when unauthenticated" do
    it "redirects to the sign-in path" do
      post generate_readable_summary_my_trial_path(nct_id)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context "when authenticated" do
    before { sign_in user }

    it "renders a turbo_stream update targeting the wrapper" do
      post_generate

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("readable-study-summary-content-#{nct_id}")
    end

    it "enqueues the generation job for a brand-new record" do
      expect { post_generate }
        .to have_enqueued_job(GenerateReadableStudySummaryJob).with(nct_id)
    end

    it "does not enqueue when a fresh pending record already exists" do
      create(:readable_study_summary, nct_id: nct_id)

      expect { post_generate }.not_to have_enqueued_job(GenerateReadableStudySummaryJob)
    end

    it "does not enqueue when the record is already completed" do
      create(:readable_study_summary, :completed, nct_id: nct_id)

      expect { post_generate }.not_to have_enqueued_job(GenerateReadableStudySummaryJob)
    end

    it "renders the completed state with the summary content and AI label" do
      create(:readable_study_summary, :completed, nct_id: nct_id,
        content: "Plain words anyone can read.")

      post_generate

      expect(response.body).to include("<p>Plain words anyone can read.</p>")
      expect(response.body).to include("AI-generated, plain-language summary")
      expect(response.body).to include("<svg")
    end

    it "re-enqueues and touches a stale pending record" do
      record = create(:readable_study_summary, nct_id: nct_id)
      record.update_column(:updated_at, (ReadableStudySummary::STALE_AFTER + 1.minute).ago)

      expect { post_generate }
        .to have_enqueued_job(GenerateReadableStudySummaryJob).with(nct_id)
    end

    it "resets a failed record to pending and re-enqueues" do
      create(:readable_study_summary, :failed, nct_id: nct_id)

      expect { post_generate }
        .to have_enqueued_job(GenerateReadableStudySummaryJob).with(nct_id)

      record = ReadableStudySummary.find_by(nct_id: nct_id)
      expect(record.pending?).to be(true)
      expect(record.error_message).to be_nil
    end

    context "with a malformed nct_id" do
      let(:bad_id) { "FOO" }

      def post_bad_generate
        post generate_readable_summary_my_trial_path(bad_id), headers: turbo_headers
      end

      it "does not create a record" do
        expect { post_bad_generate }.not_to change(ReadableStudySummary, :count)
      end

      it "does not enqueue the generation job" do
        expect { post_bad_generate }.not_to have_enqueued_job(GenerateReadableStudySummaryJob)
      end

      it "responds with unprocessable entity" do
        post_bad_generate

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
