require "rails_helper"

RSpec.describe Buttons::ButtonComponent, type: :component do
  def render_button(color: nil)
    render_inline(described_class.new(path: "/search", text: "Search", color: color))
  end

  described_class::VARIANTS.each_key do |variant|
    it "renders the #{variant} variant" do
      render_button(color: variant)

      expect(page.find("a")[:class]).to include(described_class::VARIANTS.fetch(variant).split.first)
    end
  end

  it "falls back to secondary when no colour is given" do
    render_button

    expect(page.find("a")[:class]).to include("text-navy-600")
  end

  # Five call sites used to pass a colour with no case behind it and silently
  # get the default. DeleteButtonComponent was one, so every delete rendered as
  # an ordinary neutral button.
  it "raises on a variant it does not have, rather than rendering the wrong button" do
    expect { render_button(color: "clear_navy") }
      .to raise_error(ArgumentError, /Unknown button variant/)
  end

  it "names the variants it does have in the error" do
    expect { render_button(color: "nonsense") }
      .to raise_error(ArgumentError, /primary, secondary, quiet, destructive/)
  end

  describe "the destructive variant" do
    it "is visually distinct from secondary, so a delete does not look ordinary" do
      destructive = described_class::VARIANTS.fetch("destructive")
      secondary = described_class::VARIANTS.fetch("secondary")

      expect(destructive).not_to eq(secondary)
      expect(destructive).to include("crit")
    end

    it "is what the delete button asks for" do
      render_inline(Buttons::DeleteButtonComponent.new(path: "/saved_trials/1"))

      expect(page.find("a")[:class]).to include("text-crit")
    end
  end
end
