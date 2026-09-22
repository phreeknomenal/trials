require "rails_helper"

RSpec.describe Page::Trials::TakingPartComponent, type: :component do
  let(:study) do
    {
      interventions: [{type: "DRUG", name: "Semaglutide", description: "Taken weekly."}],
      design_allocation: "RANDOMIZED",
      design_masking: "DOUBLE",
      design_primary_purpose: "TREATMENT",
      design_intervention_model: "PARALLEL",
      primary_outcomes: [{measure: "HbA1c", description: "x", time_frame: "Baseline to 52 weeks"}],
      enrollment_count: 1240,
      enrollment_type: "ESTIMATED"
    }
  end

  describe "what it builds from the registry" do
    before { render_inline(described_class.new(study: study)) }

    it "lists what you would receive" do
      expect(page.text).to include("Semaglutide")
      expect(page.text).to include("Drug")
    end

    # The enums that carry a real consequence are read into plain language;
    # "RANDOMIZED" tells a patient nothing.
    it "says what randomised actually means for you" do
      expect(page.text).to include("At random, not chosen by you or your doctor")
    end

    it "says what the masking means for you" do
      expect(page.text).to include("Neither you nor the study team is told")
    end

    # The study's own words, quoted rather than parsed into a duration the app
    # would be inventing.
    it "quotes the outcome time frame rather than computing a duration" do
      expect(page.text).to include("Baseline to 52 weeks")
    end

    it "marks an estimated enrollment as estimated" do
      expect(page.text).to include("About 1,240 people expected")
    end

    it "says taking part is something you can stop" do
      expect(page.text).to include("You can leave a study at any point")
    end
  end

  # The board draws a visit schedule: three-hour screening, tablet daily, clinic
  # every three weeks, scans every twelve. None of it is in the data.
  it "invents no visit schedule" do
    render_inline(described_class.new(study: study))

    expect(page.text).not_to match(/every \d+ weeks/i)
    expect(page.text).not_to include("Screening visit")
  end

  it "falls back to the humanised enum for a design value with no plain reading" do
    render_inline(described_class.new(study: {design_primary_purpose: "HEALTH_SERVICES_RESEARCH"}))

    expect(page.text).to include("Health services research")
  end

  it "renders nothing when the registry gave none of it" do
    render_inline(described_class.new(study: {}))

    expect(page.text.strip).to be_empty
  end

  it "counts a non-estimated enrollment as actual" do
    render_inline(described_class.new(study: study.merge(enrollment_type: "ACTUAL")))

    expect(page.text).to include("1,240 people taking part")
  end
end
