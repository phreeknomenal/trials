require "rails_helper"

RSpec.describe "The study detail page", type: :request do
  let(:user) { create(:user) }
  let(:nct_id) { "NCT01234567" }

  let(:study) do
    {
      nct_id: nct_id,
      title: "A Study of Something",
      summary: "The registry's own description of the study.",
      status: "RECRUITING",
      phase: "PHASE2",
      study_type: "INTERVENTIONAL",
      sponsor: "A Sponsor",
      min_age: "18 Years",
      max_age: "75 Years",
      sex: "ALL",
      conditions: ["Asthma"],
      inclusion_criteria: "Adults aged 18 to 75.",
      exclusion_criteria: "Currently in another study.",
      interventions: [{type: "DRUG", name: "Semaglutide", description: "Weekly."}],
      design_allocation: "RANDOMIZED",
      design_masking: "DOUBLE",
      primary_outcomes: [{measure: "HbA1c", description: "x", time_frame: "Baseline to 52 weeks"}],
      enrollment_count: 1240,
      enrollment_type: "ESTIMATED",
      locations: ["Birmingham, Alabama"],
      locations_detailed: [{display: "Birmingham, Alabama", near_you: true, city: "Birmingham", state: "Alabama"}],
      central_contacts: [],
      overall_officials: []
    }
  end

  before { allow(ClinicalTrialClient).to receive(:get_study).with(nct_id).and_return(study) }

  # An anchor pointing at a section that no longer exists is silent: the link
  # renders, the click does nothing. This caught #interventions after the
  # section became #taking-part.
  it "has a section for every link in its own sidebar" do
    sign_in user

    get search_path(nct_id)

    anchors = response.body.scan(/href="#([a-z-]+)"/).flatten.uniq
    ids = response.body.scan(/id="([a-z-]+)"/).flatten.uniq

    expect(anchors).not_to be_empty
    expect(anchors - ids).to be_empty, "sidebar links with no section: #{(anchors - ids).join(", ")}"
  end

  # The correction that started this: the registry's wording is what you read,
  # and the rewrite is something you ask for.
  describe "the readable summary" do
    it "shows the registry's own text" do
      get search_path(nct_id)

      expect(response.body).to include("The registry's own description")
    end

    it "labels it as the registry's, so the two blocks are not interchangeable" do
      get search_path(nct_id)

      expect(response.body).to include("From the registry record")
    end

    it "puts the registry text before the offer to rewrite it" do
      get search_path(nct_id)

      registry = response.body.index("own description of the study")
      offer = response.body.index("readable version")

      expect(registry).to be_present
      expect(offer).to be_present
      expect(registry).to be < offer
    end
  end

  describe "the criteria split" do
    before { sign_in user }

    # Which groups appear depends on what the checker could answer, and the
    # component omits an empty group rather than rendering a reassuring zero.
    # The grouping itself is covered in the component spec, with controlled
    # input; this only proves the section is wired into the page.
    it "renders the grouped criteria rather than a flat list" do
      get search_path(nct_id)

      expect(response.body).to include("Do you qualify")
      expect(response.body).to include("What you meet")
    end

    it "always says only the study team can confirm" do
      get search_path(nct_id)

      expect(response.body).to include("Only the study team can confirm")
    end

    it "keeps the registry's own criteria text on the page, collapsed" do
      get search_path(nct_id)

      expect(response.body).to include("own criteria")
      expect(response.body).to include("Inclusion criteria")
    end

    # Signed out there is no profile to check against, so there is nothing to
    # split and the section does not render.
    it "is absent signed out" do
      sign_out user

      get search_path(nct_id)

      expect(response.body).not_to include("What you meet")
    end
  end

  describe "what taking part involves" do
    it "is built from the registry's design and interventions" do
      get search_path(nct_id)

      expect(response.body).to include("Semaglutide")
      expect(response.body).to include("At random, not chosen by you or your doctor")
      expect(response.body).to include("Baseline to 52 weeks")
    end

    it "invents no visit schedule" do
      get search_path(nct_id)

      expect(response.body).not_to include("Screening visit")
    end
  end
end
