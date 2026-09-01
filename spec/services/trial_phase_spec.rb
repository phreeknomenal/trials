require "rails_helper"

RSpec.describe TrialPhase do
  # The shapes ClinicalTrialClient actually emits, taken from the captured
  # fixtures in spec/fixtures/trials. Anything that passes against invented
  # strings like "Phase 4" proves nothing, because that is the format the old
  # code assumed and it never appeared in a real payload.
  describe ".levels" do
    it "normalizes the registry enum" do
      expect(described_class.levels("PHASE4")).to eq(["phase4"])
      expect(described_class.levels("EARLY_PHASE1")).to eq(["early_phase1"])
      expect(described_class.levels("NA")).to eq(["na"])
    end

    it "splits a trial that spans several phases" do
      expect(described_class.levels("PHASE2, PHASE3")).to eq(["phase2", "phase3"])
    end

    it "is empty for a missing phase" do
      expect(described_class.levels(nil)).to be_empty
      expect(described_class.levels("")).to be_empty
    end
  end

  describe ".lowest" do
    it "reads a single phase" do
      expect(described_class.lowest("PHASE3")).to eq(TrialPhase::PHASE3)
    end

    # Someone in a seamless PHASE1/PHASE2 study is exposed to phase 1 risk.
    # Reporting phase 2 would understate what they are agreeing to.
    it "takes the least-tested phase of a multi-phase trial" do
      expect(described_class.lowest("PHASE1, PHASE2")).to eq(TrialPhase::PHASE1)
      expect(described_class.lowest("PHASE2, PHASE3")).to eq(TrialPhase::PHASE2)
    end

    it "is nil for NA, which is not on the scale" do
      expect(described_class.lowest("NA")).to be_nil
    end

    it "is nil for a missing or unrecognized phase" do
      expect(described_class.lowest(nil)).to be_nil
      expect(described_class.lowest("SOMETHING_ELSE")).to be_nil
    end
  end

  describe ".at_least?" do
    it "compares against the ordering" do
      expect(described_class.at_least?("PHASE3", TrialPhase::PHASE2)).to be(true)
      expect(described_class.at_least?("PHASE1", TrialPhase::PHASE2)).to be(false)
      expect(described_class.at_least?("PHASE2", TrialPhase::PHASE2)).to be(true)
    end

    it "treats EARLY_PHASE1 as less tested than PHASE1" do
      expect(described_class.at_least?("EARLY_PHASE1", TrialPhase::PHASE1)).to be(false)
    end

    it "is false for NA and for nothing at all" do
      expect(described_class.at_least?("NA", TrialPhase::PHASE1)).to be(false)
      expect(described_class.at_least?(nil, TrialPhase::PHASE1)).to be(false)
    end
  end

  describe ".not_applicable?" do
    it "recognizes the registry marker" do
      expect(described_class.not_applicable?("NA")).to be(true)
      expect(described_class.not_applicable?("PHASE4")).to be(false)
      expect(described_class.not_applicable?(nil)).to be(false)
    end
  end

  describe ".label" do
    it "renders a single phase for display" do
      expect(described_class.label("PHASE4")).to eq("Phase 4")
      expect(described_class.label("EARLY_PHASE1")).to eq("Early Phase 1")
      expect(described_class.label("NA")).to eq("Not Applicable")
    end

    it "collapses a multi-phase trial" do
      expect(described_class.label("PHASE2, PHASE3")).to eq("Phase 2/3")
    end

    it "is nil when no phase is named, so callers choose how to render it" do
      expect(described_class.label(nil)).to be_nil
      expect(described_class.label("SOMETHING_ELSE")).to be_nil
    end
  end

  describe "against the captured fixtures" do
    it "recognizes every phase value the real payloads carry" do
      phases = TrialFixtures.fixture_ids.map { |id| TrialFixtures.trial_fixture(id)[:phase] }

      # Guards the test itself: if the fixtures stop carrying phases, this
      # spec would pass vacuously.
      expect(phases.compact).not_to be_empty

      phases.compact.each do |phase|
        expect(described_class.levels(phase)).to all(satisfy { |level|
          TrialPhase::ORDER.include?(level) || level == TrialPhase::NOT_APPLICABLE
        }), "unrecognized phase in fixtures: #{phase.inspect}"
      end
    end
  end
end
