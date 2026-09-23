require "rails_helper"

RSpec.describe ProfileStrength do
  let(:profile) { create(:user).profile }

  # Only the optional steps that affect matching count. The four required steps
  # are behind the onboarding gate, so reporting them as progress is padding,
  # and about_you says in its own prompt that it does not affect matching.
  it "counts only the steps that change a score" do
    expect(described_class.new(profile).total).to eq(2)
  end

  it "does not count about_you, which cannot change a match" do
    expect(described_class::SCORING_STEPS.keys).not_to include("about_you")
  end

  context "with nothing optional answered" do
    before { profile.update_columns(willing_travel_miles: nil, remote_visit_preference: nil, trial_type_preference: nil, risk_tolerance: nil) }

    it "reports none answered" do
      strength = described_class.new(profile)

      expect(strength.answered).to eq(0)
      expect(strength.remaining).to eq(2)
      expect(strength).not_to be_complete
    end

    it "names what is missing, so the dashboard can link to it" do
      headings = described_class.new(profile).unanswered.map { |_slug, step, _| step.heading }

      expect(headings).to include("How far would you travel?")
    end
  end

  # Skipping a step advances onboarding_step without writing anything, so the
  # step number cannot be used to tell an answer from a skip.
  it "counts a step as answered only when a field actually has a value" do
    profile.update_columns(willing_travel_miles: 50, remote_visit_preference: nil,
      trial_type_preference: nil, risk_tolerance: nil, onboarding_step: Onboarding.complete_number)

    strength = described_class.new(profile)

    expect(strength.answered).to eq(1)
    expect(strength.percent).to eq(50)
  end

  it "is complete once both are answered" do
    profile.update_columns(willing_travel_miles: 50, trial_type_preference: "either")

    expect(described_class.new(profile)).to be_complete
  end
end
