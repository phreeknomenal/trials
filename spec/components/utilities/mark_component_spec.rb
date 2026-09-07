require "rails_helper"

RSpec.describe Utilities::MarkComponent, type: :component do
  it "draws the two faces of the needle" do
    render_inline(described_class.new)

    paths = page.all("path", visible: :all).map { |node| node[:d] }
    expect(paths).to eq(["M30.6 0 L30.6 116 L0 96 Z", "M33.4 0 L33.4 116 L64 96 Z"])
  end

  it "leaves the channel empty rather than painting it" do
    render_inline(described_class.new)

    expect(page.all("path", visible: :all).size).to eq(2)
  end

  # Asserted against the raw markup because Nokogiri downcases attribute names
  # on read, and SVG needs the capital B.
  it "keeps the measured aspect so the mark cannot be stretched" do
    render_inline(described_class.new)

    expect(rendered_content).to include('viewBox="0 0 64 116"')
    expect(page.find("svg", visible: :all)[:class]).to include("w-auto")
  end

  # Tailwind only emits classes it finds literally in source, so a height built
  # by interpolation would render with no height at all.
  it "uses a literal height class" do
    render_inline(described_class.new(height: 12))

    expect(page.find("svg", visible: :all)[:class]).to include("h-12")
  end

  it "refuses a height it has no literal class for" do
    expect { render_inline(described_class.new(height: 99)) }.to raise_error(KeyError)
  end

  it "is decorative by default, since it sits beside the wordmark" do
    render_inline(described_class.new)

    expect(page.find("svg", visible: :all)[:"aria-hidden"]).to eq("true")
  end

  it "takes a label when it stands alone" do
    render_inline(described_class.new(label: "Dira Health"))

    svg = page.find("svg", visible: :all)
    expect(svg[:role]).to eq("img")
    expect(svg[:"aria-label"]).to eq("Dira Health")
  end

  it "restains both faces for dark mode" do
    render_inline(described_class.new)

    classes = page.all("path", visible: :all).map { |node| node[:class] }
    expect(classes.first).to include("dark:fill-navy-400")
    expect(classes.last).to include("dark:fill-sky-300")
  end
end
