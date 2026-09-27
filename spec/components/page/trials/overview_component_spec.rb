require "rails_helper"

# The section carries the registry's own words and the offer to rewrite them.
# None of it was covered, which is how the rewrite came to render above half the
# text it rewrites and the offer came to be a bare button with no sentence round
# it.
RSpec.describe Page::Trials::OverviewComponent, type: :component do
  let(:nct_id) { "NCT01234567" }

  let(:study) do
    {
      summary: "A study of something.",
      detailed_description: "The dense clinical version of the same thing.",
      conditions: ["Leukemia", "Lymphoma"]
    }
  end

  def render_study(overrides = {})
    render_inline(described_class.new(study: study.merge(overrides), nct_id: nct_id))
  end

  it "labels whose words these are, beside the heading" do
    render_study

    expect(page).to have_css("h2", text: "What this study is testing")
    expect(page.text).to include("From the registry record")
  end

  # It used to sit behind a "Detailed Description" dropdown. Its density is the
  # argument for the rewrite offered underneath, and a reader who never opens
  # the dropdown never sees why that offer is there.
  it "shows the detailed description unedited rather than behind a dropdown" do
    render_study

    expect(page.text).to include("The dense clinical version of the same thing.")
    expect(page).to have_no_css("summary", text: "Detailed Description")
  end

  # The board's chip row is the study design, which "What taking part involves"
  # already says in sentences further down the page. The conditions are the
  # answer to this section's own heading and appear nowhere else on it.
  it "chips the conditions" do
    render_study

    expect(page).to have_css("ul[aria-label='Conditions this study covers'] li", text: "Leukemia")
    expect(page).to have_css("ul[aria-label='Conditions this study covers'] li", text: "Lymphoma")
  end

  it "leaves the chip row out when the registry named no condition" do
    render_study(conditions: [])

    expect(page).to have_no_css("ul[aria-label='Conditions this study covers']")
  end

  # The registry separates paragraphs with a single newline, which simple_format
  # rendered as <br> inside one <p>: four paragraphs of clinical prose arrived as
  # an unbroken wall with no gap anywhere in it.
  it "breaks the registry's prose on its own newlines" do
    render_study(detailed_description: "First paragraph.\nSecond paragraph.\n\nThird paragraph.")

    paragraphs = page.all("#study-overview p").map { |n| n.text.strip }

    expect(paragraphs).to include("First paragraph.", "Second paragraph.", "Third paragraph.")
  end

  describe "the rewrite offer" do
    it "says what it does, how long it takes and what happens to the original" do
      render_study

      expect(page.text).to include("Hard to follow?")
      expect(page.text).to include("the original stays on this page")
      expect(page).to have_button("Generate a plain-language version")
    end

    # It rendered between the summary and the detailed description, so the
    # rewrite appeared above half of what it was rewriting.
    it "comes after the words it is offering to rewrite" do
      render_study

      body = page.native.to_html

      expect(body.index("dense clinical version")).to be < body.index("Hard to follow?")
    end

    it "is not offered when the registry gave nothing to rewrite" do
      render_study(summary: nil, detailed_description: nil)

      expect(page).to have_no_button("Generate a plain-language version")
    end
  end
end
