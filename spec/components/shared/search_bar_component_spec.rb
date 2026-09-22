require "rails_helper"

RSpec.describe Shared::SearchBarComponent, type: :component do
  let(:conditions) { [Condition.new(name: "Asthma"), Condition.new(name: "Type 2 diabetes")] }

  describe "the full variant" do
    before { render_inline(described_class.new(url: "/search", conditions: conditions, popular: ["Asthma"])) }

    # The container sits one rung above the controls inside it, so a 12px field
    # inside a 16px bar reads settled.
    it "uses the search radius, with control-radius fields inside it" do
      expect(page.find("form")[:class]).to include("rounded-search")
      expect(page.all("select").map { |n| n[:class] }).to all(include("rounded-control"))
    end

    # A placeholder alone disappears the moment someone types, which is exactly
    # when they most need to know what the box was for.
    it "labels every field visibly, not with a placeholder alone" do
      %w[Condition Location Distance].each do |name|
        expect(page).to have_css("label", text: name)
      end

      page.all("label").each do |label|
        expect(label[:class]).not_to include("sr-only")
      end
    end

    it "offers real examples in the placeholder rather than a generic one" do
      expect(page.text).to include("Breast cancer")
    end

    it "carries a search icon in the button, which a submit input could not hold" do
      expect(page).to have_css("button[type='submit'] svg")
    end

    it "offers popular conditions as pills below" do
      expect(page).to have_css("a", text: "Asthma")
    end
  end

  describe "the compact variant" do
    before { render_inline(described_class.new(url: "/search", variant: :compact, conditions: conditions)) }

    it "drops to the card radius, being a toolbar rather than the page's subject" do
      expect(page.find("form")[:class]).to include("rounded-card")
    end

    it "says Update, because the person has already told us what they want" do
      expect(page).to have_css("button[type='submit']", text: "Update")
    end

    # Still labelled, just not visibly: the compact bar sits under a heading
    # that has already said what it searches.
    it "keeps its labels for screen readers" do
      expect(page.all("label", visible: :all).map { |n| n[:class] }).to all(include("sr-only"))
    end

    it "offers no popular conditions" do
      expect(page).to have_no_css("a")
    end
  end

  it "never offers more than four popular conditions" do
    render_inline(described_class.new(url: "/search", popular: %w[One Two Three Four Five Six]))

    expect(page).to have_css("a", count: 4)
  end

  it "falls back to a free text field when there are no conditions to list" do
    render_inline(described_class.new(url: "/search", conditions: []))

    expect(page).to have_css("input[name='condition']")
  end

  it "raises on a variant nobody designed" do
    expect { described_class.new(url: "/search", variant: :inline) }
      .to raise_error(ArgumentError, /Unknown search bar variant/)
  end
end
