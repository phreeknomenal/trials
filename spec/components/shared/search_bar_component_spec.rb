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
      %w[Condition Location].each do |name|
        expect(page).to have_css("label", text: name)
      end

      page.all("label").each do |label|
        expect(label[:class]).not_to include("sr-only")
      end
    end

    # Was asserted against page.text, which worked only while the placeholder
    # was an <option> label. It is a placeholder attribute on a text field now.
    it "offers real examples in the placeholder rather than a generic one" do
      expect(page.find("input[name='condition']")[:placeholder]).to include("Breast cancer")
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

  # The full variant offered "Within 25 / 50 / 100 miles" and nothing read it.
  # It survived two PRs unseen because the compact variant hid it and nothing
  # used the full one, so it would have appeared the moment the landing page
  # rendered this component for the purpose it was written for.
  #
  # There is no distance in the data at all: locations_detailed carries a
  # near_you boolean from a string match on city and state.
  describe "distance" do
    it "is not offered on either variant" do
      %i[full compact].each do |variant|
        render_inline(described_class.new(url: "/search", variant: variant))

        expect(page).to have_no_css("label", text: "Distance")
        expect(page.native.to_html).not_to include("distance")
      end
    end

    it "is not a constant anyone can reach for" do
      expect(described_class).not_to be_const_defined(:DISTANCES)
    end
  end

  # The condition field was a select built from the conditions table, so the app
  # could search for 72 conditions and no others. Somebody with sarcoidosis or
  # myasthenia gravis had no way to ask, while the registry behind it accepts
  # any term at all. The control was narrower than the thing it queried.
  describe "the condition field" do
    let(:conditions) { [Condition.new(name: "asthma"), Condition.new(name: "lupus")] }

    before { render_inline(described_class.new(url: "/search", conditions: conditions)) }

    it "lets someone type a condition that is not in the table" do
      expect(page).to have_css("input[name='condition']")
      expect(page).to have_no_css("select[name='condition']")
    end

    it "still suggests the ones we know" do
      list = page.find("input[name='condition']")[:list]

      expect(page).to have_css("datalist##{list} option[value='asthma']", visible: :all)
      expect(page).to have_css("datalist##{list} option[value='lupus']", visible: :all)
    end

    it "gives the list an id the input actually points at" do
      list = page.find("input[name='condition']")[:list]

      expect(list).to be_present
      expect(page).to have_css("datalist##{list}", visible: :all)
    end
  end
end
