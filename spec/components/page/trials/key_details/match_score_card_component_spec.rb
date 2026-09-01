require "rails_helper"

RSpec.describe Page::Trials::KeyDetails::MatchScoreCardComponent, type: :component do
  def explanation_for(tolerance, phase)
    profile = create(:profile, risk_tolerance: tolerance)
    component = described_class.new(
      trial_score: 50, match_level: "fair", score_breakdown: {},
      profile: profile, trial: {phase: phase}
    )

    component.send(:generate_phase_risk_explanation)
  end

  def score_for(tolerance, phase)
    profile = create(:profile, risk_tolerance: tolerance)

    TrialScorer.new(profile, {phase: phase}).send(:score_phase_risk)
  end

  describe "#generate_phase_risk_explanation" do
    # This component explains the phase_risk number the scorer produced. When
    # the two disagree the user reads a contradiction, which is what happened
    # before TrialPhase: this component tested include?("Phase 4") against
    # "PHASE4" and told people a genuine Phase 4 trial did not match their
    # preference for approved treatments.
    it "agrees with the score it is explaining" do
      registry_phases = %w[EARLY_PHASE1 PHASE1 PHASE2 PHASE3 PHASE4 NA]

      Profile::RISK_TOLERANCE_OPTIONS.each do |tolerance|
        registry_phases.each do |phase|
          score = score_for(tolerance, phase)
          text = explanation_for(tolerance, phase)

          case score
          when 100
            expect(text).to start_with("✓"),
              "#{tolerance.inspect} scored #{phase} at 100 but the text is not positive: #{text.inspect}"
          when 0
            expect(text).to start_with("✗"),
              "#{tolerance.inspect} scored #{phase} at 0 but the text is not negative: #{text.inspect}"
          else
            expect(text).not_to start_with("✓", "✗"),
              "#{tolerance.inspect} scored #{phase} at #{score} but the text is absolute: #{text.inspect}"
          end
        end
      end
    end

    # It interpolated the raw registry value, rendering "This Phase PHASE4 trial".
    it "renders the display form of the phase, not the registry enum" do
      text = explanation_for(Profile::APPROVED_ONLY, "PHASE4")

      expect(text).to include("Phase 4")
      expect(text).not_to include("PHASE4")
    end

    it "renders a multi-phase trial readably" do
      text = explanation_for(Profile::TESTED, "PHASE2, PHASE3")

      expect(text).to include("Phase 2/3")
    end

    it "reports nothing to weigh when the trial names no phase" do
      expect(explanation_for(Profile::TESTED, nil)).to eq("Risk information not available.")
    end

    it "reports nothing to weigh when the profile states no tolerance" do
      expect(explanation_for(nil, "PHASE4")).to eq("Risk information not available.")
    end
  end
end
