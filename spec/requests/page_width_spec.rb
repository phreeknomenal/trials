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
    it "caps the measure near the board's 1180px of content" do
      expect(container).to include("max-w-6xl")
    end

    it "centres it and keeps a gutter at every width" do
      expect(container).to include("mx-auto", "px-5")
    end
  end

  # The point of the module. A page that hand-writes its own width is how this
  # drifted the first time, and it drifts silently.
  describe "no page writes its own width" do
    it "has no template left on the old full-bleed gutters" do
      offenders = page_templates.select { |p| File.read(p).match?(/lg:px-(24|36)\b/) }
        .map { |p| p.sub("#{Rails.root}/", "") }

      expect(offenders).to be_empty,
        "#{offenders.join(", ")} still set their own page gutters. Use Layout::PageWidth::CONTAINER."
    end

    it "has no template capping itself at a different step" do
      offenders = page_templates.select { |p| File.read(p).match?(/mx-auto[^"]*max-w-(4xl|5xl|7xl)\b/) }
        .map { |p| p.sub("#{Rails.root}/", "") }

      expect(offenders).to be_empty,
        "#{offenders.join(", ")} centre themselves at a width the chrome does not use."
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
        expect(response.body.scan(container.split.first).count).to be >= 3
      end
    end
  end
end
