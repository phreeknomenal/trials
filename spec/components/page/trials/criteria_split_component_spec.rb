require "rails_helper"

RSpec.describe Page::Trials::CriteriaSplitComponent, type: :component do
  def item(label, status, explanation = "because")
    {label: label, status: status, explanation: explanation, is_expandable: false, full_text: nil}
  end

  let(:checklist) do
    [
      item("Age", "met"),
      item("Sex/Gender", "met"),
      item("Recruitment Status", "unknown"),
      item("Health Conditions", "warning"),
      item("Prior therapy", "not_met")
    ]
  end

  # The old checklist was one flat list, so "your age fits" and "your age rules
  # you out" sat together with nothing but an icon colour between them.
  describe "the three groups" do
    before { render_inline(described_class.new(checklist: checklist)) }

    it "separates what you meet" do
      expect(page).to have_css("h3", text: "What you meet")
    end

    it "separates what the team still checks" do
      expect(page).to have_css("h3", text: "What the team still checks")
    end

    # A hard failure is not the same as something the team will confirm.
    it "separates what rules you out" do
      expect(page).to have_css("h3", text: "What rules you out")
    end

    it "reports the total against the whole checklist" do
      expect(page.text).to include("You meet 2 of 5")
    end

    # The board sets the first two beside each other. The third is not on the
    # board at all, and running it full width underneath keeps it from reading
    # as one half of a pair.
    it "sets the board's two groups as columns and the third across both" do
      headings = page.all("section h3").map { |h| h.text.strip }
      spanning = page.all("section.md\\:col-span-2 h3").map { |h| h.text.strip }

      expect(headings).to eq(["What you meet", "What the team still checks", "What rules you out"])
      expect(spanning).to eq(["What rules you out"])
    end

    # The group used to carry one icon for everything in it, which flattened two
    # different answers: the team will verify this, and nobody knows this.
    it "marks a criterion the team verifies differently from one nothing answered" do
      warning = page.find("li", text: "Health Conditions")
      unknown = page.find("li", text: "Recruitment Status")

      expect(warning).to have_css(".text-warn")
      expect(unknown).to have_no_css(".text-warn")
    end
  end

  # A "What rules you out" heading with nothing under it invites a second read.
  it "leaves out a group with nothing in it" do
    render_inline(described_class.new(checklist: [item("Age", "met")]))

    expect(page).to have_no_css("h3", text: "What rules you out")
    expect(page).to have_css("h3", text: "What you meet")
  end

  it "treats a status nobody mapped as something the team checks, not as met" do
    render_inline(described_class.new(checklist: [item("Something new", "info")]))

    expect(page).to have_css("h3", text: "What the team still checks")
    expect(page).to have_no_css("h3", text: "What you meet")
  end

  it "renders nothing at all without a checklist" do
    render_inline(described_class.new(checklist: []))

    expect(page.text.strip).to be_empty
  end

  # A number scored against a profile is only as current as the profile.
  describe "the caveat" do
    it "always says only the study team can confirm" do
      render_inline(described_class.new(checklist: checklist))

      expect(page.text).to include("Only the study team can confirm")
    end

    it "dates the profile it checked against, and links to it" do
      profile = create(:user).profile

      render_inline(described_class.new(checklist: checklist, profile: profile))

      expect(page.text).to include("last updated on")
      expect(page).to have_link("Update my profile")
    end

    it "offers no profile link when there is no profile" do
      render_inline(described_class.new(checklist: checklist))

      expect(page).to have_no_link("Update my profile")
    end
  end

  # The board draws the number as a solid tile beside the heading. It is not
  # tinted by tier here: the tint is how a score reads against the scores either
  # side of it on a result list, and this one is alone on the page.
  describe "the score tile" do
    it "carries the number and what it counts" do
      render_inline(described_class.new(checklist: checklist, trial_score: 92, match_level: "excellent"))

      expect(page.text).to include("92")
      expect(page.text).to include("MATCH")
    end

    it "is absent when nothing scored the study" do
      render_inline(described_class.new(checklist: checklist))

      expect(page.text).not_to include("MATCH")
    end
  end

  it "keeps the registry's own wording collapsed, being long and clinical" do
    expandable = [{label: "Criteria", status: "unknown", explanation: "x",
                   is_expandable: true, full_text: "INCLUSION CRITERIA: ..."}]

    render_inline(described_class.new(checklist: expandable))

    expect(page).to have_css("details summary", text: "Read the study's own wording")
  end
end
