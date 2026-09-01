require "rails_helper"

RSpec.describe Page::Trials::PhaseStatusExplainerComponent, type: :component do
  def explanation_for(phase)
    described_class.new(phase: phase).send(:phase_explanation)
  end

  describe "#phase_explanation" do
    it "explains each phase the registry emits" do
      expect(explanation_for("PHASE1")).to include("Phase 1")
      expect(explanation_for("PHASE2")).to include("Phase 2")
      expect(explanation_for("PHASE3")).to include("Phase 3")
      expect(explanation_for("PHASE4")).to include("Phase 4")
    end

    # EARLY_PHASE1 had no entry and fell through to the "not applicable" text,
    # describing the earliest stage of human testing as not being a phase.
    it "explains an early phase 1 trial as early testing, not as unphased" do
      text = explanation_for("EARLY_PHASE1")

      expect(text).to include("Early Phase 1")
      expect(text).not_to include("Not applicable")
    end

    it "explains a study with no FDA phase" do
      expect(explanation_for("NA")).to include("Not applicable")
    end

    # Matches how TrialScorer weighs it: the risk taken on is the earliest phase.
    it "explains a multi-phase trial by its least-tested phase" do
      expect(explanation_for("PHASE1, PHASE2")).to include("Phase 1")
    end

    it "explains nothing when no phase is named" do
      expect(explanation_for(nil)).to be_nil
      expect(explanation_for("")).to be_nil
    end
  end
end
