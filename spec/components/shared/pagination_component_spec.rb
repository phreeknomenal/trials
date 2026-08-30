require "rails_helper"

RSpec.describe Shared::PaginationComponent, type: :component do
  def pagy_for(page:, count: 100, limit: 10)
    Pagy::Offset.new(count: count, page: page, limit: limit)
  end

  def render_for(page:, count: 100, limit: 10, unit: nil)
    render_inline(described_class.new(
      pagy: pagy_for(page: page, count: count, limit: limit),
      path_for: ->(p) { "/things?page=#{p}" },
      unit: unit
    ))
  end

  describe "with a single page" do
    it "renders nothing" do
      result = render_for(page: 1, count: 5, limit: 10)

      expect(result.to_html.strip).to be_empty
    end
  end

  describe "on the first page" do
    it "renders next but not previous" do
      html = render_for(page: 1).to_html

      expect(html).to include("Next")
      expect(html).not_to include("Previous")
    end

    it "links next to page 2" do
      expect(render_for(page: 1).to_html).to include("/things?page=2")
    end
  end

  describe "on the last page" do
    it "renders previous but not next" do
      html = render_for(page: 10).to_html

      expect(html).to include("Previous")
      expect(html).not_to include("Next")
    end
  end

  describe "in the middle" do
    it "renders both" do
      html = render_for(page: 5).to_html

      expect(html).to include("Previous", "Next")
    end

    it "links to the adjacent pages" do
      html = render_for(page: 5).to_html

      expect(html).to include("/things?page=4", "/things?page=6")
    end
  end

  describe "position indicator" do
    it "renders the current page and total" do
      expect(render_for(page: 3).to_html).to match(/Page\s+3\s+of\s+10/)
    end

    it "omits the count when no unit is given" do
      expect(render_for(page: 3).to_html).not_to include("(100")
    end

    it "includes a pluralised count when a unit is given" do
      expect(render_for(page: 3, unit: "user").to_html).to include("100 users")
    end
  end

  describe "accessibility" do
    it "labels the nav landmark" do
      expect(render_for(page: 5).to_html).to include('aria-label="Pagination"')
    end

    it "marks prev and next with rel attributes" do
      html = render_for(page: 5).to_html

      expect(html).to include('rel="prev"', 'rel="next"')
    end
  end
end
