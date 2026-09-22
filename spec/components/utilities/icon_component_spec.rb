require "rails_helper"

RSpec.describe Utilities::IconComponent, type: :component do
  describe "sizing" do
    # Tailwind scans source for literal class strings, so a class assembled at
    # runtime is never emitted. Every size this component offers has to exist as
    # literal text somewhere Tailwind reads, which is what SIZES is for.
    described_class::SIZES.each do |size, expected|
      it "renders size #{size} as #{expected}" do
        render_inline(described_class.new("search", size: size))

        expect(page.find("svg", visible: :all)[:class]).to include(expected)
      end
    end

    it "falls back to 6 when no size is given" do
      render_inline(described_class.new("search"))

      expect(page.find("svg", visible: :all)[:class]).to include("w-6 h-6")
    end

    it "raises on a size it has no literal class for, rather than failing silently" do
      expect { render_inline(described_class.new("search", size: 99)) }
        .to raise_error(ArgumentError, /Unsupported icon size/)
    end

    it "keeps any classes passed through options" do
      render_inline(described_class.new("search", size: 5, options: {class: "text-gray-400"}))

      expect(page.find("svg", visible: :all)[:class]).to include("text-gray-400")
    end
  end

  describe "every size has a literal in the compiled stylesheet" do
    let(:stylesheet) { Rails.root.join("app/assets/builds/tailwind.css") }

    # Guards the actual failure. The component can name a class perfectly and
    # still render nothing if Tailwind never emitted it.
    described_class::SIZES.each_value do |classes|
      classes.split.each do |klass|
        it "emits .#{klass}" do
          skip "stylesheet not built" unless File.exist?(stylesheet)

          expect(File.read(stylesheet)).to include(".#{klass}{")
        end
      end
    end
  end

  # Both failures these guard against were already in the library and neither
  # announced itself: clipboard_check was an empty file that rendered a blank
  # svg, and guage stroked every path #000000, so it stayed black in dark mode
  # while every other icon followed the text colour.
  describe "the icon library" do
    partials = Dir[Rails.root.join("app/views/shared/icons/_*.html.erb")]

    it "is not empty" do
      expect(partials).not_to be_empty
    end

    partials.each do |path|
      name = File.basename(path, ".html.erb").delete_prefix("_")

      context name do
        let(:markup) { File.read(path) }

        it "draws something" do
          expect(markup.strip).not_to be_empty
        end

        it "takes its colour from the text, not a hardcoded value" do
          expect(markup).not_to match(/#[0-9A-Fa-f]{3,8}\b/)
        end
      end
    end
  end
end
