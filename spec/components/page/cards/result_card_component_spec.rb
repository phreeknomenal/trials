require "rails_helper"

RSpec.describe Page::Cards::ResultCardComponent, type: :component do
  let(:study) do
    {
      nct_id: "NCT01234567",
      title: "A Study of Something",
      phase: "Phase 2",
      status: "RECRUITING",
      conditions: ["Asthma", "COPD"],
      min_age: "18 Years",
      max_age: "75 Years",
      locations: ["Birmingham, Alabama"],
      locations_detailed: [{display: "Birmingham, Alabama", near_you: true}]
    }
  end

  def scored(total: 92, level: "excellent", breakdown: nil, disqualifiers: [])
    study.merge(
      trial_score: total,
      match_level: level,
      score_breakdown: breakdown || {age: 100, sex: 100, conditions: 100, location: 100, study_type: 50, phase_risk: 50},
      disqualifiers: disqualifiers
    )
  end

  describe "signed out" do
    before { render_inline(described_class.new(study: study, signed_in: false)) }

    # A placeholder where a number should be reads as "we scored you badly"
    # rather than "we have not met you".
    it "shows no score at all, not a greyed-out one" do
      expect(page.text).not_to include("MATCH")
    end

    it "offers to find out instead" do
      expect(page).to have_link("Check your match")
    end

    it "offers no save control, there being no account to save to" do
      expect(page).to have_no_css("[data-controller='save-trial']")
    end

    # What it leads with instead: the study's own facts.
    it "leads with the study's own phase and recruitment status" do
      expect(page.text).to include("Phase 2")
      expect(page.text).to include("Recruiting")
    end

    it "shows the ages the study is recruiting" do
      expect(page.text).to include("Ages 18 Years to 75 Years")
    end

    it "shows the conditions" do
      expect(page.text).to include("Asthma")
    end

    # near_you is derived from the profile's city and state, so signed out it
    # cannot be true.
    it "never claims a location is near you" do
      expect(page.text).not_to include("Near you")
    end
  end

  describe "signed in" do
    before { render_inline(described_class.new(study: scored, signed_in: true)) }

    it "leads with the score" do
      expect(page.text).to include("92")
      expect(page.text).to include("MATCH")
    end

    it "names the tier in words as well as colour" do
      expect(page.text).to include("Excellent match")
    end

    it "offers saving rather than signing in" do
      expect(page).to have_no_link("Check your match")
    end

    it "marks a location near the profile" do
      expect(page.text).to include("Near you")
    end
  end

  # The count has to match what was actually scored, and must not round the
  # unknowns into either column.
  describe "the criteria summary" do
    it "counts only the criteria the profile could answer" do
      render_inline(described_class.new(
        study: scored(breakdown: {age: 100, sex: 100, conditions: 100, location: 50, study_type: 50, phase_risk: 50}),
        signed_in: true
      ))

      expect(page.text).to include("Meets 3 of 6 checks")
      expect(page.text).to include("3 need more of your profile")
    end

    it "says nothing about missing profile when everything was answered" do
      render_inline(described_class.new(
        study: scored(breakdown: {age: 100, sex: 100, conditions: 100, location: 100, study_type: 100, phase_risk: 100}),
        signed_in: true
      ))

      expect(page.text).to include("Meets 6 of 6 checks")
      expect(page.text).not_to include("need more of your profile")
    end

    it "shows no summary signed out, there being no breakdown" do
      render_inline(described_class.new(study: study, signed_in: false))

      expect(page.text).not_to include("checks")
    end
  end

  # An ineligible study is a hard stop from a named failure, not a low score.
  describe "when the profile is ruled out" do
    before do
      render_inline(described_class.new(
        study: scored(total: 0, level: TrialScorer::INELIGIBLE, disqualifiers: [:age]),
        signed_in: true
      ))
    end

    it "says not eligible rather than naming a tier" do
      expect(page.text).to include("Not eligible")
    end

    it "names the criterion that stopped it" do
      expect(page.text).to include("outside the ages this study is recruiting")
    end

    it "does not also report a criteria count, which would read as a near miss" do
      expect(page.text).not_to include("checks")
    end
  end

  # The boards show all four of these. ClinicalTrialClient returns none of them.
  describe "what it refuses to invent" do
    it "never shows a distance in miles, there being none in the data" do
      render_inline(described_class.new(study: scored, signed_in: true))

      expect(page.text).not_to match(/\d+\s*mi\b/)
    end
  end
end
