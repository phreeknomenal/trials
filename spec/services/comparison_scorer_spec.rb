require "rails_helper"

RSpec.describe ComparisonScorer do
  let(:profile) do
    p = create(:user).profile
    p.conditions << Condition.create!(name: "Asthma")
    p
  end

  let(:study) do
    {
      nct_id: "NCT1", title: "A Study", status: "RECRUITING", phase: "PHASE2",
      study_type: "INTERVENTIONAL", min_age: "18 Years", max_age: "75 Years",
      sex: "ALL", conditions: ["Asthma"],
      locations_detailed: [{display: "Birmingham, Alabama", city: "Birmingham", state: "Alabama"}],
      locations: ["Birmingham, Alabama"]
    }
  end

  let(:saved) { create(:saved_trial, user: profile.user, nct_id: "NCT1", match_score: 42) }

  def scored(response = study)
    allow(ClinicalTrialClient).to receive(:get_study).with("NCT1").and_return(response)
    described_class.new(profile: profile, saved_trials: [saved]).call.first
  end

  # The point of the whole change. Scoring from the saved columns fed TrialScorer
  # empty conditions and locations, which are 40 of the 100 points between them,
  # so the same study scored differently here than on the results page.
  it "scores the study the registry holds, matching what the results page shows" do
    expected = TrialScorer.new(profile, study).calculate_score

    expect(scored.total).to eq(expected[:total])
    expect(scored.breakdown).to eq(expected[:breakdown])
  end

  it "scores conditions and location rather than defaulting them" do
    breakdown = scored.breakdown

    expect(breakdown[:conditions]).to be > 50
    expect(breakdown[:location]).to be > 50
  end

  # Proves the previous behaviour was wrong rather than merely different.
  it "differs from scoring the saved columns, which carry neither" do
    from_columns = TrialScorer.new(profile, {
      min_age: saved.min_age, max_age: saved.max_age, sex: nil,
      conditions: [], locations: [], study_type: saved.study_type,
      phase: saved.phase, status: saved.trial_status
    }).calculate_score

    expect(scored.breakdown[:conditions]).not_to eq(from_columns[:breakdown][:conditions])
  end

  describe "when the registry cannot be reached" do
    it "falls back to the stored score and says it is stale" do
      result = scored({error: "Search temporarily unavailable."})

      expect(result).to be_stale
      expect(result.total).to eq(saved.match_score)
      expect(result.breakdown).to be_nil
    end

    it "does the same on a timeout" do
      allow(ClinicalTrialClient).to receive(:get_study).and_raise(Timeout::Error)

      result = described_class.new(profile: profile, saved_trials: [saved]).call.first

      expect(result).to be_stale
    end

    # One unreachable study should cost that row its breakdown, not the page.
    it "does not raise" do
      allow(ClinicalTrialClient).to receive(:get_study).and_raise(StandardError, "boom")

      expect { described_class.new(profile: profile, saved_trials: [saved]).call }.not_to raise_error
    end

    it "is not stale when the fetch worked" do
      expect(scored).not_to be_stale
    end
  end

  it "fetches once per trial, comparison being capped at three" do
    allow(ClinicalTrialClient).to receive(:get_study).and_return(study)

    described_class.new(profile: profile, saved_trials: [saved]).call

    expect(ClinicalTrialClient).to have_received(:get_study).once
  end
end
