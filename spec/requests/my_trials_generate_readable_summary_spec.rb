require "rails_helper"

RSpec.describe "POST /my_trials/:id/generate_readable_summary", type: :request do
  let(:user) { create(:user) }
  let(:nct_id) { "NCT01234567" }
  let(:turbo_headers) { {"Accept" => "text/vnd.turbo-stream.html"} }

  before { sign_in user }

  def post_generate
    post generate_readable_summary_my_trial_path(nct_id), headers: turbo_headers
  end

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
end
