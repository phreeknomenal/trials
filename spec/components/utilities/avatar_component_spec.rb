require "rails_helper"

RSpec.describe Utilities::AvatarComponent, type: :component do
  def render_with(avatar: nil, initials: "DW", size: nil)
    args = {avatar: avatar, initials: initials}
    args[:size] = size if size

    render_inline(described_class.new(**args))
  end

  def profile_with_avatar
    create(:profile).tap do |profile|
      profile.avatar.attach(
        io: Rails.root.join("spec/fixtures/files/avatar.png").open,
        filename: "avatar.png",
        content_type: "image/png"
      )
    end
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

  # Uploads were served at full size and scaled down by CSS, so a multi-megabyte
  # phone photo was downloaded to fill a 40px circle.
  describe "with an avatar" do
    let(:avatar) { profile_with_avatar.avatar }

    it "renders an image" do
      expect(render_with(avatar: avatar).css("img")).not_to be_empty
    end

    it "serves a resized variant rather than the original upload" do
      src = render_with(avatar: avatar).css("img").first["src"]

      expect(src).to include("representations")
    end

    it "cuts the variant at twice the display size, for retina" do
      component = described_class.new(avatar: avatar, initials: "DW", size: 96)

      expect(component.variant_size).to eq(192)
    end

    it "reports width and height so the box is reserved before the image lands" do
      img = render_with(avatar: avatar, size: 96).css("img").first

      expect(img["width"]).to eq("96")
      expect(img["height"]).to eq("96")
    end

    it "loads lazily" do
      expect(render_with(avatar: avatar).css("img").first["loading"]).to eq("lazy")
    end

    it "is decorative, since every call site has adjacent text or a label" do
      expect(render_with(avatar: avatar).css("img").first["alt"]).to eq("")
    end

    it "defaults to 40, the size three of the six call sites use" do
      expect(described_class.new(avatar: avatar, initials: "DW").size).to eq(40)
    end

    # A PDF or SVG attachment has no variant. Falling back beats raising.
    it "serves the original when the attachment cannot be varied" do
      allow(avatar).to receive(:variable?).and_return(false)

      expect(described_class.new(avatar: avatar, initials: "DW").image).to eq(avatar)
    end
  end
end
