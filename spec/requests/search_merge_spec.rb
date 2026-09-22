require "rails_helper"

# SearchController#index and #show used to have a second copy in
# MyTrialsController#search and #show. The two drifted: only the signed-out pair
# rendered the registry's error, only the signed-in pair scored anything, and
# both were linked from the header at once.
#
# These cover the thing the merge has to get right, which is that the whole
# difference between the two is whether there is a profile.
RSpec.describe "The merged search", type: :request do
  let(:user) { create(:user) }
  let(:nct_id) { "NCT01234567" }

  let(:study) do
    {
      nct_id: nct_id,
      title: "A Study of Something",
      summary: "A study of something.",
      conditions: ["Asthma"],
      status: "RECRUITING",
      phase: "PHASE2",
      study_type: "INTERVENTIONAL",
      min_age: "18 Years",
      max_age: "65 Years",
      sex: "ALL",
      interventions: [],
      locations: [],
      central_contacts: [],
      overall_officials: []
    }
  end

  def stub_search(studies: [study], error: nil)
    allow(ClinicalTrialClient).to receive(:advanced_search).and_return(
      {studies: studies, total_count: studies.length, error: error, next_page_token: nil}
    )
  end

  describe "GET /search signed out" do
    it "renders without a profile" do
      stub_search

      get search_index_path(condition: "Asthma")

      expect(response).to have_http_status(:ok)
    end

    it "shows no match score, because there is nobody to score against" do
      stub_search

      get search_index_path(condition: "Asthma")

      expect(response.body).to include("A Study of Something")
      expect(response.body).not_to include("% Match")
    end

    it "shows the registry's error, which only the signed-out page used to do" do
      stub_search(studies: [], error: "The registry did not answer.")

      get search_index_path(condition: "Asthma")

      expect(response.body).to include("The registry did not answer.")
    end

    it "offers no sort control, since sorting by match needs a profile" do
      stub_search

      get search_index_path(condition: "Asthma")

      expect(response.body).not_to include("Best match for you")
    end
  end

  describe "GET /search signed in" do
    before { sign_in user }

    it "shows a match score on each study" do
      stub_search

      get search_index_path(condition: "Asthma")

      expect(response.body).to include("% Match")
    end

    it "offers the sort control" do
      stub_search

      get search_index_path(condition: "Asthma")

      expect(response.body).to include("Best match for you")
    end

    # The profile carries a condition and Birmingham, Alabama, so a signed-in
    # visitor who types nothing still lands on results rather than an empty form.
    # This is the behaviour my_trials#search existed for.
    it "falls back to the profile's condition and location" do
      user.profile.conditions << Condition.create!(name: "Asthma")
      stub_search

      get search_index_path

      expect(ClinicalTrialClient).to have_received(:advanced_search)
        .with(hash_including(condition: "Asthma", location: "Birmingham, Alabama"))
    end

    it "does not search at all when there is nothing to search for" do
      stub_search

      get search_index_path

      expect(ClinicalTrialClient).not_to have_received(:advanced_search)
    end
  end

  describe "GET /search/:id" do
    before { allow(ClinicalTrialClient).to receive(:get_study).with(nct_id).and_return(study) }

    it "renders signed out" do
      get search_path(nct_id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("A Study of Something")
    end

    it "invites a signed-out reader to sign in rather than offering to save" do
      get search_path(nct_id)

      expect(response.body).to include("Sign in to save this study")
    end

    it "offers saving, not signing in, once there is a profile" do
      sign_in user

      get search_path(nct_id)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Sign in to save this study")
    end
  end

  # The old paths were the signed-in links since launch, so they redirect
  # rather than 404.
  describe "the old my_trials paths" do
    before { sign_in user }

    it "sends /my_trials/search to /search, keeping the query" do
      get "/my_trials/search?condition=Asthma"

      expect(response).to redirect_to("/search?condition=Asthma")
    end

    it "sends a bare /my_trials/search to /search" do
      get "/my_trials/search"

      expect(response).to redirect_to("/search")
    end

    it "sends /my_trials/NCT... to the study on /search" do
      get "/my_trials/#{nct_id}"

      expect(response).to redirect_to("/search/#{nct_id}")
    end

    it "leaves the dashboard's own paths alone" do
      get "/my_trials/trial_comparison"

      expect(response).not_to have_http_status(:moved_permanently)
    end
  end
end
