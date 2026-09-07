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
end
