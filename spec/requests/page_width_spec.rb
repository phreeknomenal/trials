require "rails_helper"

# The header and the footer have to start where the page under them starts.
#
# They did not. At a 1720px viewport the landing page, search, the dashboard,
# the profile and saved studies began their content at 96px; About, the FAQ and
# the privacy policy began at 377px; and the chrome began at 313px. Three
# conventions, none of them agreeing, so the wordmark sat 217px inboard of the
# page beneath it.
#
# Every board on the canvas is a 1440 frame where the header, the footer and
# every section share the same gutters, so they are flush by construction. The
# app lost that because each page chose a container as it was built.
#
# These specs are proxies and worth knowing as such: they assert that the same
# container string is used, not that two boxes line up on screen. A real check
# needs a browser, and one was run. What this catches is the next page that
# writes its own width instead of reading the shared one.
RSpec.describe "Page width", type: :request do
  let(:container) { Layout::PageWidth::CONTAINER }

  # Anything under app/views that is not admin. Admin is deliberately exempt:
  # it renders wide read-only tables under its own layout, and capping those
  # would force a horizontal scroll on the one surface where seeing every
  # column at once is the point.
  def page_templates
    Dir.glob(Rails.root.join("app/views/**/*.html.erb")).reject do |path|
      path.include?("/admin/") || path.include?("/layouts/") ||
        path.include?("/devise/") || path.include?("/onboarding/") ||
        path.include?("/home/") || path.include?("/pwa/")
    end
  end

  describe "the shared container" do
    it "insets from the edge rather than centring a column" do
      expect(container).to include("lg:px-24")
    end

    it "keeps a gutter at narrow widths too" do
      expect(container).to include("px-5")
    end

    # Capping it centred at max-w-6xl was the first attempt and the wrong one:
    # 1152px leaves 281px of empty page on each side of a 1713px display, and
    # the pages that had been full bleed lost width to match the chrome. The
    # chrome was what was wrong, so the chrome is what moved.
    it "does not cap the measure" do
      expect(container).not_to match(/max-w-/)
    end
  end

  # The point of the module. A page that hand-writes its own width is how this
  # drifted the first time, and it drifts silently.
  describe "no page writes its own width" do
    # Written out literally rather than read from the constant, so that changing
    # the constant does not quietly change what this forbids.
    it "has no template hand-writing the page gutters" do
      offenders = page_templates.select { |p| File.read(p).match?(/class="[^"]*\blg:px-(24|36)\b/) }
        .map { |p| p.sub("#{Rails.root}/", "") }

      expect(offenders).to be_empty,
        "#{offenders.join(", ")} set their own page gutters. Use Layout::PageWidth::CONTAINER."
    end

    # A prose column capping itself is correct and stays. What is forbidden is a
    # template centring the *page* at its own width, which is how the content
    # pages ended up 64px narrower than the chrome.
    it "has no template centring the page at its own width" do
      offenders = page_templates.select { |p| File.read(p).match?(/mx-auto w-full max-w-/) }
        .map { |p| p.sub("#{Rails.root}/", "") }

      expect(offenders).to be_empty,
        "#{offenders.join(", ")} centre the page at a width the chrome does not use."
    end
  end

  describe "the chrome and the page agree" do
    {
      "the landing page" => "/",
      "about" => "/about",
      "the FAQ" => "/faq",
      "the privacy policy" => "/privacy",
      "the contact form" => "/contact",
      "search" => "/search"
    }.each do |name, path|
      it "renders #{name} inside the same container as the header and footer" do
        get path

        expect(response).to have_http_status(:ok)

        # The chrome renders it twice, the page at least once. Fewer than three
        # means something on this page is not using it.
        expect(response.body.scan("lg:px-24").count).to be >= 3
      end
    end
  end
end
