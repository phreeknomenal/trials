require "rails_helper"

# Regression coverage for a nil nct_id. search/show.html.erb rendered
# Page::Trials::OverviewComponent without nct_id, which defaulted to nil and
# surfaced as a confusing routing error from deep inside a partial:
#
#   No route matches {action: "generate_readable_summary", controller:
#   "my_trials", id: nil}, missing required keys: [:id]
RSpec.describe "GET /search/:id", type: :request do
  let(:user) { create(:user) }
  let(:nct_id) { "NCT01234567" }

  let(:study) do
    {
      nct_id: nct_id,
      summary: "A study of something.",
      detailed_description: "A longer description of the study.",
      conditions: ["Asthma"],
      status: "RECRUITING",
      phase: "PHASE2",
      study_type: "INTERVENTIONAL",
      sponsor: "Some Sponsor",
      enrollment_count: 100,
      start_date: "2026-01-01",
      completion_date: "2027-01-01",
      min_age: "18 Years",
      max_age: "65 Years",
      sex: "ALL",
      inclusion_criteria: "Inclusion criteria text",
      interventions: [],
      locations: [],
      central_contacts: [],
      overall_officials: []
    }
  end

  before do
    sign_in user
    allow(ClinicalTrialClient).to receive(:get_study).with(nct_id).and_return(study)
  end

  it "renders without raising" do
    get search_path(nct_id)

    expect(response).to have_http_status(:ok)
  end

  it "builds the generate-summary path with the real nct_id, not nil" do
    get search_path(nct_id)

    expect(response.body).to include("/my_trials/#{nct_id}/generate_readable_summary")
  end
end
