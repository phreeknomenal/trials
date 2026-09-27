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
      start_date: "2026-03-01",
      completion_date: "2028-09-30",
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

  # The board's form is a timeline. Its own stages are invented, but the four
  # things below do happen in this order, and the last of them was sitting in a
  # component that nothing rendered.
  describe "the timeline" do
    before { render_inline(described_class.new(study: study)) }

    it "runs in the order these things happen to you" do
      labels = page.all("ol > li > div:last-child > span:first-child").map { |s| s.text.strip }

      expect(labels).to eq(["How you are assigned", "What you would receive",
        "How long they follow you", "When the study runs"])
    end

    it "carries the study's own dates, which nothing on the page used to show" do
      expect(page.text).to include("March 1, 2026 to September 30, 2028")
    end

    it "marks only the first stage as the one you join at" do
      expect(page).to have_css("ol > li .bg-navy-600", count: 1)
      expect(page.first("ol > li")).to have_css(".bg-navy-600")
    end

    # Half of all studies publish these to the month only. Date.parse raises on
    # "2029-09", so rescuing it to nil would have dropped this stage for half
    # the registry without anything saying so.
    it "says a month-precision date to the month rather than dropping it" do
      render_inline(described_class.new(study: study.merge(start_date: "2011-06", completion_date: "2029-09")))

      expect(page.text).to include("June 2011 to September 2029")
    end

    it "drops a stage the registry said nothing about" do
      render_inline(described_class.new(study: study.except(:start_date, :completion_date)))

      expect(page.text).not_to include("When the study runs")
      expect(page.text).to include("How you are assigned")
    end
  end

  # The board draws a visit schedule: three-hour screening, tablet daily, clinic
  # every three weeks, scans every twelve. None of it is in the data.
  it "invents no visit schedule" do
    render_inline(described_class.new(study: study))

    expect(page.text).not_to include("Screening visit")
    expect(page.text).not_to match(/clinic visit every/i)
    expect(page.text).not_to match(/scans every/i)
  end

  # Not a stage in anybody's journey: it describes the study's shape rather
  # than what happens to you.
  it "keeps the study's shape out of the timeline" do
    render_inline(described_class.new(study: study))

    expect(page).to have_css("dl dt", text: "Why it is being run")
    expect(page).to have_no_css("ol li", text: "Why it is being run")
  end

  # "NA" is how the registry says a single-group study has no allocation, and
  # "How you are assigned: Not applicable" is a line that tells nobody anything.
  it "says nothing about assignment when the registry said NA" do
    render_inline(described_class.new(study: study.merge(design_allocation: "NA", design_masking: "NA")))

    expect(page.text).not_to include("How you are assigned")
    expect(page.text).not_to include("Not applicable")
  end

  # The registry escapes markdown in its free text; nothing renders it as
  # markdown, so the backslashes are debris.
  it "strips the registry's markdown escapes out of an intervention" do
    escaped = [{type: "DRUG", name: "Ruxolitinib", description: 'Age \> 4 weeks \< 2 years'}]

    render_inline(described_class.new(study: study.merge(interventions: escaped)))

    expect(page.text).to include("Age > 4 weeks < 2 years")
    expect(page.text).not_to include('\>')
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
