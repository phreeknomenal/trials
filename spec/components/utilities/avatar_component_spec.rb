require "rails_helper"

RSpec.describe Utilities::AvatarComponent, type: :component do
  def render_with(avatar: nil, initials: "DW")
    render_inline(described_class.new(avatar: avatar, initials: initials))
  end

  describe "without an avatar" do
    it "renders the initials" do
      expect(render_with(initials: "DW").to_html).to include("DW")
    end

    it "renders a background color from the palette" do
      html = render_with(initials: "DW").to_html

      expect(html).to match(/background-color: #[0-9a-f]{6}/)
    end

    it "does not render an image tag" do
      expect(render_with(initials: "DW").css("img")).to be_empty
    end
  end

  # Regression: background_color previously did initials[0].ord + initials[1].ord,
  # which raised NoMethodError on nil for anything shorter than two characters.
  describe "with single-character initials" do
    it "does not raise" do
      expect { render_with(initials: "C") }.not_to raise_error
    end

    it "renders the single letter" do
      expect(render_with(initials: "C").to_html).to include("C")
    end

    it "still produces a valid background color" do
      expect(render_with(initials: "C").to_html).to match(/background-color: #[0-9a-f]{6}/)
    end
  end

  describe "with blank initials" do
    it "does not raise" do
      expect { render_with(initials: "") }.not_to raise_error
    end

    it "falls back to the placeholder initials" do
      expect(render_with(initials: "").to_html).to include(described_class::FALLBACK_INITIALS)
    end
  end

  describe "with nil initials" do
    it "does not raise" do
      expect { render_with(initials: nil) }.not_to raise_error
    end
  end

  describe "#background_color" do
    it "always returns a color from the palette" do
      %w[A AB ABC DW C].each do |value|
        color = described_class.new(avatar: nil, initials: value).background_color

        expect(described_class::AVATAR_COLORS).to include(color)
      end
    end
  end
end
