require "rails_helper"

RSpec.describe Onboarding::PanelComponent, type: :component do
  def panel_for(slug)
    render_inline(described_class.new(step: Onboarding.steps.find { |s| s.slug == slug }))
  end

  it "has an answer for every step, so no step shows an empty panel" do
    Onboarding.steps.each do |step|
      expect(described_class::NOTES[step.slug]).to be_present
      expect(described_class::CRITERIA).to have_key(step.slug)
    end
  end

  # Read from TrialScorer::WEIGHTS rather than restated, so retuning the scorer
  # cannot leave a wrong number on the wizard.
  describe "the weight it reports" do
    it "adds up the criteria the step actually feeds" do
      panel = described_class.new(step: Onboarding.steps.find { |s| s.slug == "basics" })

      expect(panel.weight).to eq(TrialScorer::WEIGHTS[:age] + TrialScorer::WEIGHTS[:sex])
    end

    it "shows it on the panel" do
      panel_for("conditions")

      expect(page.text).to include("#{TrialScorer::WEIGHTS[:conditions]} of 100")
    end

    it "never claims more than the scorer has to give" do
      Onboarding.steps.each do |step|
        expect(described_class.new(step: step).weight).to be <= 100
      end
    end
  end

  # Saying every question matters would be untrue, and the prompts for these two
  # steps already say the opposite.
  describe "steps that change no score" do
    %w[identity about_you].each do |slug|
      it "says #{slug} changes nothing rather than showing a zero bar" do
        panel_for(slug)

        expect(page.text).to include("This step changes no score")
      end
    end
  end

  # Reference, not persuasion: the prompt already says to answer only if you
  # have a view.
  describe "the phase reference" do
    it "appears on the preferences step" do
      panel_for("preferences")

      expect(page.text).to include("First tests in people")
    end

    it "appears nowhere else" do
      panel_for("location")

      expect(page.text).not_to include("First tests in people")
    end
  end

  it "counts the steps from Onboarding rather than saying seven" do
    panel_for("identity")

    expect(page.text).to include("#{Onboarding.count} questions")
  end

  # The panel was first written for a navy ground, so its text was white. On the
  # light gradient that is invisible.
  it "writes on ink, not on white" do
    panel_for("conditions")

    expect(page.native.to_html).not_to include("text-white")
  end
end
