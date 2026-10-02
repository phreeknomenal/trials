require "rails_helper"

# The test cache is a real memory store, so the rate limits are exercised.
RSpec.describe "Writing prescreen questions", type: :request do
  let(:nct_id) { "NCT01234567" }
  let(:study) { {inclusion_criteria: "Diagnosis of asthma", exclusion_criteria: "Current smoker"} }
  let(:turbo_headers) { {"Accept" => "text/vnd.turbo-stream.html, text/html"} }

  before { allow(ClinicalTrialClient).to receive(:get_study).and_return(study) }

  def generate(id = nct_id) = post(study_prescreen_path(id), headers: turbo_headers)

  def nct(n) = format("NCT%08d", n)

  it "queues the questions and sends the visitor back to the study" do
    expect { generate }.to have_enqueued_job(GenerateStudyPrescreenJob).with(nct_id)
    expect(response).to redirect_to(search_path(nct_id))
  end

  it "does not queue a second job while one is running" do
    create(:study_prescreen, nct_id: nct_id)

    expect { generate }.not_to have_enqueued_job(GenerateStudyPrescreenJob)
  end

  it "retries a failed study" do
    create(:study_prescreen, nct_id: nct_id, status: "failed", error_message: "x")

    expect { generate }.to have_enqueued_job(GenerateStudyPrescreenJob)
    expect(StudyPrescreen.find_by!(nct_id: nct_id)).to have_attributes(status: "pending", error_message: nil)
  end

  it "requeues a job that died mid-run" do
    create(:study_prescreen, nct_id: nct_id, updated_at: 10.minutes.ago)

    expect { generate }.to have_enqueued_job(GenerateStudyPrescreenJob)
  end

  describe "a study that already has questions" do
    it "does nothing while the criteria are unchanged" do
      create(:study_prescreen, :completed, nct_id: nct_id, criteria_digest: StudyPrescreen.digest_for(study))

      expect { generate }.not_to have_enqueued_job(GenerateStudyPrescreenJob)
    end

    it "rewrites them once the study edits its criteria" do
      create(:study_prescreen, :completed, nct_id: nct_id, criteria_digest: "old")

      expect { generate }.to have_enqueued_job(GenerateStudyPrescreenJob)
      expect(StudyPrescreen.find_by!(nct_id: nct_id).status).to eq("pending")
    end

    # Unreachable criteria hash differently from the real ones, which would
    # read as "changed" and spend a call on nothing.
    it "leaves them alone when the registry cannot be reached" do
      allow(ClinicalTrialClient).to receive(:get_study).and_return({error: "Unable to load"})
      create(:study_prescreen, :completed, nct_id: nct_id, criteria_digest: "old")

      expect { generate }.not_to have_enqueued_job(GenerateStudyPrescreenJob)
    end
  end

  it "rejects an id that is not an NCT id" do
    expect { generate("DROP TABLE") }.not_to have_enqueued_job(GenerateStudyPrescreenJob)
    expect(response).to have_http_status(:unprocessable_entity)
  end

  describe "limits" do
    it "stops an anonymous visitor past the hourly limit, in the prescreen panel" do
      StudyPrescreensController::ANONYMOUS_HOURLY_LIMIT.times { |i| generate(nct(i)) }

      generate(nct(99))

      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include("study-prescreen-#{nct(99)}")
      expect(response.body).to include("too many questions")
    end

    it "caps new studies per day, counting rows written" do
      allow(StudyPrescreensController).to receive(:daily_limit).and_return(1)
      create(:study_prescreen, nct_id: nct(1))

      generate(nct(2))

      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include("as many questions as we can today")
    end

    # rate_limit keys its counters by controller. Spending summaries must not
    # spend questions, or one feature's traffic would lock out the other.
    it "keeps a separate hourly budget from readable summaries" do
      ReadableSummariesController::ANONYMOUS_HOURLY_LIMIT.times do |i|
        post readable_summary_path(nct(i)), headers: turbo_headers
      end
      post readable_summary_path(nct(40)), headers: turbo_headers
      expect(response).to have_http_status(:too_many_requests)

      generate(nct(50))

      expect(response).to have_http_status(:see_other)
    end
  end
end
