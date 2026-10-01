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
      expect(response.body).not_to include("MATCH")
    end

    it "offers to find out instead of showing an empty score" do
      stub_search

      get search_index_path(condition: "Asthma")

      expect(response.body).to include("Check your match")
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

      expect(response.body).to include("MATCH")
      expect(response.body).not_to include("Check your match")
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

  # query.locn is a place-name match: "35203" returned nothing at all while
  # "Birmingham, Alabama" returned four, and the field has invited a zip since
  # it was written.
  describe "searching by postal code" do
    before do
      ZipCode.create!(zip: "35203", city: "Birmingham", state: "Alabama", lat: 33.521, lon: -86.8066)
      sign_in user
    end

    it "asks the registry for the town, not the digits" do
      expect(ClinicalTrialClient).to receive(:advanced_search)
        .with(hash_including(location: "Birmingham, Alabama"))
        .and_return({studies: [], total_count: 0})

      get "/search", params: {condition: "asthma", location: "35203"}
    end

    it "asks for a radius instead once one is chosen" do
      expect(ClinicalTrialClient).to receive(:advanced_search)
        .with(hash_including(within_miles: 50, origin: [33.521, -86.8066]))
        .and_return({studies: [], total_count: 0})

      get "/search", params: {condition: "asthma", location: "35203", within_miles: "50"}
    end

    # The cards still say how far each study is from the reader's own zip, so a
    # notice reading "we could not tell where to measure from" above "128 miles
    # away" would be two true sentences contradicting each other.
    it "says which filter was dropped rather than that it cannot measure" do
      user.profile.update_columns(zip_code: "35203")
      stub_search(studies: [])

      get "/search", params: {condition: "asthma", location: "Chicago, IL", within_miles: "50"}

      expect(response.body).to include("50 mile filter was not applied")
      expect(response.body).not_to include("could not tell where to measure")
    end
  end

  # The save control needs to know which of the listed studies are already
  # saved. Asked per card that is one query per row.
  describe "saved state on the results page" do
    before { sign_in user }

    it "loads the page's saved trials in a single query" do
      create(:saved_trial, user: user, nct_id: nct_id)
      stub_search(studies: Array.new(5) { |i| study.merge(nct_id: "NCT0000000#{i}") } + [study])

      queries = 0
      counter = ->(_name, _start, _finish, _id, payload) {
        queries += 1 if payload[:sql]&.include?("saved_trials")
      }

      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
        get search_index_path(condition: "Asthma")
      end

      expect(queries).to eq(1)
    end

    it "asks for nothing when signed out" do
      sign_out user
      stub_search

      queries = 0
      counter = ->(_name, _start, _finish, _id, payload) {
        queries += 1 if payload[:sql]&.include?("saved_trials")
      }

      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
        get search_index_path(condition: "Asthma")
      end

      expect(queries).to eq(0)
    end
  end
end
