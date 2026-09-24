require "rails_helper"

RSpec.describe Buttons::ButtonStyles do
  describe ".variant" do
    it "raises on an unknown name rather than rendering the wrong button" do
      expect { described_class.variant("lavender") }.to raise_error(ArgumentError, /Unknown button variant/)
    end

    it "falls back to the default when given nothing" do
      expect(described_class.variant(nil)).to eq(described_class::VARIANTS.fetch("secondary"))
    end
  end

  # The landing page's closing call to action rendered two invisible buttons in
  # light mode: `secondary` is navy-600 text on a navy-600 border with no fill,
  # and the panel behind it is navy-600. The same colour, a contrast ratio of
  # 1 to 1.
  #
  # A green suite could not see it, and neither could a dark-mode screenshot:
  # the dark: rules swap the text to navy-300, so the buttons appear in dark and
  # vanish in light, which is the default.
  describe "the on-navy variants" do
    it "fills the primary one with white so it reads on a navy panel" do
      classes = described_class.classes("primary-on-navy").split

      expect(classes).to include("bg-white", "text-navy-700")
    end

    it "outlines the secondary one in white rather than navy" do
      classes = described_class.classes("secondary-on-navy").split

      expect(classes).to include("border-white", "text-white")
    end

    # The panel is navy in both themes, so a button on it must not restyle
    # itself when the page goes dark. That swap is what hid the original bug.
    it "carries no dark: rules, because the panel is navy in both themes" do
      %w[primary-on-navy secondary-on-navy].each do |name|
        expect(described_class.classes(name)).not_to match(/\bdark:/),
          "#{name} changes in dark mode, but the panel it sits on does not"
      end
    end

    it "never paints navy on navy" do
      %w[primary-on-navy secondary-on-navy].each do |name|
        classes = described_class.classes(name).split

        expect(classes).not_to include("text-navy-600")
        expect(classes).not_to include("border-navy-600")
      end
    end
  end

  # Every variant shares the radius, the focus ring and the disabled treatment,
  # which is the whole reason this module exists: five call sites used to write
  # their own and three of them disagreed.
  describe "what every variant shares" do
    it "puts each one on the control rung of the radius ladder" do
      described_class::VARIANTS.each_key do |name|
        expect(described_class.classes(name)).to include("rounded-control")
      end
    end

    it "gives each one a visible focus ring" do
      described_class::VARIANTS.each_key do |name|
        expect(described_class.classes(name)).to include("focus-visible:outline-2")
      end
    end
  end
end
