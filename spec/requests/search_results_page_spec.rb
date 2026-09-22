require "rails_helper"

RSpec.describe "The results page", type: :request do
  let(:user) { create(:user) }

  let(:study) do
    {
      nct_id: "NCT01234567", title: "A Study of Something", status: "RECRUITING",
      phase: "PHASE2", study_type: "INTERVENTIONAL", min_age: "18 Years",
      max_age: "75 Years", conditions: ["Asthma"], locations: ["Birmingham, Alabama"]
    }
  end

  def stub_search(studies: [study], error: nil)
    allow(ClinicalTrialClient).to receive(:advanced_search).and_return(
      {studies: studies, total_count: studies.length, error: error, next_page_token: nil}
    )
  end

  describe "the empty state" do
    before { stub_search(studies: []) }

    # Naming the search back is what makes it clear the app understood the
    # question and the answer was genuinely nothing.
    it "names what was searched for" do
      get search_index_path(condition: "Sickle cell", location: "Birmingham")

      expect(response.body).to include("Sickle cell")
      expect(response.body).to include("Birmingham")
    end

    it "offers to drop the location, which is something the app can do" do
      get search_index_path(condition: "Sickle cell", location: "Birmingham")

      expect(response.body).to include("Search everywhere instead")
    end

    it "does not offer to drop a location when none was given" do
      get search_index_path(condition: "Sickle cell")

      expect(response.body).not_to include("Search everywhere instead")
    end

    it "blames the filters when the filters are what emptied it" do
      stub_search(studies: [study])

      get search_index_path(condition: "Asthma", phase: ["PHASE3"])

      expect(response.body).to include("none of them match the filters")
      expect(response.body).to include("Clear the filters")
    end

    it "prompts for a condition before anything has been searched" do
      get search_index_path

      expect(response.body).to include("Start with a condition")
    end
  end

  describe "the filter sidebar" do
    before { sign_in user }

    it "offers the phases actually present in the results" do
      stub_search(studies: [study, study.merge(nct_id: "NCT2", phase: "PHASE3")])

      get search_index_path(condition: "Asthma")

      expect(response.body).to include("Phase 2")
      expect(response.body).to include("Phase 3")
    end

    # The counts are counts within these results. Saying otherwise would be a
    # number the app cannot stand behind.
    it "says the counts are for this search rather than the registry" do
      stub_search

      get search_index_path(condition: "Asthma")

      expect(response.body).to include("not for the whole registry")
    end

    it "renders NA as a phase nobody has to decode" do
      stub_search(studies: [study.merge(phase: "NA")])

      get search_index_path(condition: "Asthma")

      expect(response.body).to include("Not applicable")
      expect(response.body).not_to include(">NA<")
    end

    it "offers hiding ineligible studies only when there is a profile to judge by" do
      stub_search

      get search_index_path(condition: "Asthma")
      expect(response.body).to include("Hide studies you cannot join")

      sign_out user
      get search_index_path(condition: "Asthma")
      expect(response.body).not_to include("Hide studies you cannot join")
    end
  end

  # Dropping a filter from a pagination link is how a paginated page silently
  # loses its refinements.
  describe "keeping refinements across pages" do
    before { sign_in user }

    it "carries the filters into the next page link" do
      stub_search(studies: Array.new(24) { |i| study.merge(nct_id: "NCT#{i}") })

      get search_index_path(condition: "Asthma", phase: ["PHASE2"])

      expect(response.body).to include("phase%5B%5D=PHASE2")
    end
  end

  describe "the sort control" do
    it "is offered to a signed-in visitor" do
      sign_in user
      stub_search

      get search_index_path(condition: "Asthma")

      expect(response.body).to include("Best match for you")
    end

    it "is absent signed out, there being no profile to sort against" do
      stub_search

      get search_index_path(condition: "Asthma")

      expect(response.body).not_to include("Best match for you")
    end
  end
end
