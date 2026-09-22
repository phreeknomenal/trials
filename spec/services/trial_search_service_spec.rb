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

  # The registry's search takes a condition and a location and nothing else, so
  # phase and study type are applied here, over a batch already fetched.
  describe "refining" do
    let(:batch) do
      [
        study.merge(nct_id: "NCT1", phase: "PHASE2", study_type: "INTERVENTIONAL"),
        study.merge(nct_id: "NCT2", phase: "PHASE3", study_type: "INTERVENTIONAL"),
        study.merge(nct_id: "NCT3", phase: "NA", study_type: "OBSERVATIONAL")
      ]
    end

    def refine(filters, sort_by: nil)
      described_class.new(profile: profile, search_params: {condition: "Asthma"}, filters: filters)
        .search(sort_by: sort_by)
    end

    before { stub_search(batch) }

    it "keeps only the phases asked for" do
      expect(refine({phase: ["PHASE2"]})[:studies].map { |s| s[:nct_id] }).to eq(["NCT1"])
    end

    it "treats several values of one filter as or" do
      expect(refine({phase: ["PHASE2", "PHASE3"]})[:studies].length).to eq(2)
    end

    it "treats different filters as and" do
      result = refine({phase: ["PHASE2"], study_type: ["OBSERVATIONAL"]})

      expect(result[:studies]).to be_empty
    end

    it "reports the filtered total, not the registry's" do
      expect(refine({phase: ["PHASE2"]})[:total_count]).to eq(1)
    end

    it "says it refined, so the page can say so too" do
      expect(refine({phase: ["PHASE2"]})[:refined]).to be(true)
      expect(refine({})[:refined]).to be(false)
    end

    it "ignores blank filter values rather than matching nothing" do
      expect(refine({phase: ["", nil]})[:studies].length).to eq(3)
    end

    # A filter that removed its own option from the sidebar would strand
    # whoever ticked it.
    it "counts facets before filtering, not after" do
      phases = refine({phase: ["PHASE2"]})[:facets][:phase].to_h

      expect(phases.keys).to contain_exactly("PHASE2", "PHASE3", "NA")
    end

    it "offers facets on an unfiltered search too" do
      expect(refine({})[:facets][:study_type].to_h)
        .to eq({"INTERVENTIONAL" => 2, "OBSERVATIONAL" => 1})
    end

    # Filtering a page of 10 would leave three results on page one and seven on
    # page two, the registry not knowing what was removed.
    it "paginates over what survived the filter" do
      first = described_class.new(profile: profile, search_params: {condition: "Asthma"},
        page: 1, page_size: 2, filters: {study_type: ["INTERVENTIONAL"]}).search

      expect(first[:studies].length).to eq(2)
      expect(first[:has_next_page]).to be(false)
    end
  end

  describe "hiding studies the profile cannot join" do
    before do
      stub_search([study.merge(nct_id: "NCT1"), study.merge(nct_id: "NCT2", min_age: "90 Years")])
    end

    it "drops the ineligible ones when asked" do
      kept = described_class.new(profile: profile, search_params: {condition: "Asthma"},
        filters: {hide_ineligible: "1"}).search[:studies]

      expect(kept.map { |s| s[:match_level] }).not_to include(TrialScorer::INELIGIBLE)
    end

    it "keeps them otherwise" do
      kept = described_class.new(profile: profile, search_params: {condition: "Asthma"}).search[:studies]

      expect(kept.length).to eq(2)
    end

    # Without this the filter test passes trivially whenever both studies happen
    # to be eligible.
    it "has something to hide in the first place" do
      kept = described_class.new(profile: profile, search_params: {condition: "Asthma"}).search[:studies]

      expect(kept.map { |s| s[:match_level] }).to include(TrialScorer::INELIGIBLE)
    end
  end
end
