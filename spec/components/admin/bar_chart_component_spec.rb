require "rails_helper"

RSpec.describe Admin::BarChartComponent, type: :component do
  describe "with all-zero values" do
    let(:component) { described_class.new(series: {"a" => 0, "b" => 0}) }

    it "does not divide by zero" do
      expect { render_inline(component) }.not_to raise_error
    end

    it "renders every bar at zero width" do
      expect(component.percent_for(0)).to eq(0)
    end
  end

  describe "with values" do
    let(:component) { described_class.new(series: {"a" => 5, "b" => 10}) }

    it "sizes bars relative to the maximum" do
      expect(component.percent_for(10)).to eq(100)
      expect(component.percent_for(5)).to eq(50)
    end

    it "renders a row per entry" do
      html = render_inline(component).to_html

      expect(html).to include("a", "b", "width: 100%", "width: 50%")
    end
  end

  describe "with a single value" do
    it "renders a full-width bar" do
      expect(described_class.new(series: {"only" => 3}).percent_for(3)).to eq(100)
    end
  end

  describe "with an empty series" do
    it "renders the empty message" do
      html = render_inline(described_class.new(series: {}, empty_message: "Nothing here")).to_html

      expect(html).to include("Nothing here")
    end
  end
end
