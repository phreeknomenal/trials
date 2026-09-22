require "rails_helper"

RSpec.describe TrialSearchService do
  let(:profile) { create(:user).profile }

  let(:study) do
    {
      nct_id: "NCT01234567",
      title: "A Study of Something",
      status: "RECRUITING",
      phase: "PHASE2",
      study_type: "INTERVENTIONAL",
      min_age: "18 Years",
      max_age: "75 Years",
      conditions: ["Asthma"],
      locations: []
    }
  end

  def stub_search(studies)
    allow(ClinicalTrialClient).to receive(:advanced_search).and_return(
      {studies: studies, total_count: studies.length, error: nil, next_page_token: nil}
    )
  end

  def search(with_profile: profile)
    described_class.new(profile: with_profile, search_params: {condition: "Asthma"}).search
  end

  describe "scoring each study" do
    before { stub_search([study]) }

    it "merges the score onto the study" do
      expect(search[:studies].first[:trial_score]).to be_present
    end

    it "merges the breakdown, which the result card counts criteria from" do
      expect(search[:studies].first[:score_breakdown]).to include(:age, :sex, :conditions)
    end

    # Carried through so a row can say which criterion rules someone out rather
    # than only greying itself down to zero.
    it "merges the disqualifiers" do
      expect(search[:studies].first).to have_key(:disqualifiers)
    end
  end

  describe "without a profile" do
    before { stub_search([study]) }

    # This is what makes one search serve both signed in and signed out: the
    # service does not branch, it just scores nothing when there is nobody to
    # score against.
    it "returns the studies" do
      expect(search(with_profile: nil)[:studies].length).to eq(1)
    end

    it "leaves every scoring key nil rather than omitting them" do
      result = search(with_profile: nil)[:studies].first

      expect(result[:trial_score]).to be_nil
      expect(result[:match_level]).to be_nil
      expect(result[:score_breakdown]).to be_nil
      expect(result[:disqualifiers]).to be_nil
    end
  end
end
