require "rails_helper"

RSpec.describe Page::Trials::LocationsComponent, type: :component do
  def site(city:, state: nil, country: "United States", facility: "#{city} Medical Center", status: "RECRUITING")
    {
      facility: facility,
      city: city,
      state: state,
      country: country,
      status: status,
      display: [city, state, country].compact.join(", ")
    }
  end

  let(:profile) { create(:user).profile.tap { |p| p.update!(state: "Alabama") } }

  def render_sites(sites, with_profile: nil)
    render_inline(described_class.new(study: {locations_detailed: sites}, profile: with_profile))
  end

  # The registry gives a facility name on 100% of locations and the client used
  # to drop it, so the page led with "Birmingham, Alabama".
  it "leads with the site's own name, not just its city" do
    render_sites([site(city: "Birmingham", state: "Alabama", facility: "UAB Hospital")])

    expect(page.text).to include("UAB Hospital")
    expect(page.text).to include("Birmingham, Alabama, United States")
  end

  # A study of twenty sites can be recruiting while this one has closed.
  describe "the site's own recruiting state" do
    it "says a recruiting site is enrolling" do
      render_sites([site(city: "Birmingham", state: "Alabama")])

      expect(page.text).to include("Enrolling now")
    end

    it "does not call a site that stopped enrolling open" do
      render_sites([site(city: "Birmingham", state: "Alabama", status: "ACTIVE_NOT_RECRUITING")])

      expect(page.text).not_to include("Enrolling now")
      expect(page.text).to include("Active not recruiting")
    end

    it "says nothing when the registry gave no per-site status" do
      render_sites([site(city: "Birmingham", state: "Alabama", status: nil)])

      expect(page.text).not_to include("Enrolling now")
    end
  end

  describe "the summary" do
    # The median study has one site. The summary would only repeat the row.
    it "is absent for a single site" do
      render_sites([site(city: "Birmingham", state: "Alabama")], with_profile: profile)

      expect(page.text).not_to match(/\d+ sites?\b/)
    end

    it "counts the sites and the countries" do
      render_sites([site(city: "Toronto", country: "Canada"), site(city: "Osaka", country: "Japan")])

      expect(page.text).to include("2 sites across 2 countries.")
    end

    it "names the country when they are all in one" do
      render_sites([site(city: "Birmingham", state: "Alabama"), site(city: "Mobile", state: "Alabama")])

      expect(page.text).to include("2 sites in United States.")
    end

    # The sentence somebody actually came for.
    it "says how many are in the reader's own state" do
      render_sites([site(city: "Birmingham", state: "Alabama"), site(city: "Toronto", country: "Canada")],
        with_profile: profile)

      expect(page.text).to include("1 in Alabama.")
    end

    # 58% of recruiting studies have no US sites at all. "None" is the answer,
    # not a reason to hide the section.
    it "says so when none of them are" do
      render_sites([site(city: "Osaka", country: "Japan"), site(city: "Kyoto", country: "Japan")],
        with_profile: profile)

      expect(page.text).to include("None in Alabama.")
      expect(page.text).to include("Osaka")
    end
  end

  describe "ordering and the cap" do
    let(:many) do
      [site(city: "Osaka", country: "Japan"), site(city: "Lyon", country: "France")] +
        Array.new(6) { |i| site(city: "City#{i}", country: "Spain") } +
        [site(city: "Birmingham", state: "Alabama")]
    end

    it "puts the reader's own state first" do
      render_sites(many, with_profile: profile)

      expect(page.first("ul li").text).to include("Birmingham")
    end

    it "shows six and puts the rest behind a disclosure" do
      render_sites(many, with_profile: profile)

      expect(page.all("ul").first.all("li").length).to eq(6)
      expect(page).to have_css("details summary", text: "Show the other 3 sites")
    end

    # It never filters: hiding the far ones would empty the section for the
    # majority of studies, and where the sites are is the answer.
    # visible: :all because a closed <details> hides its contents from Capybara,
    # which is the point: they are on the page, not on screen.
    it "keeps every site on the page" do
      render_sites(many, with_profile: profile)

      expect(page.all("li", visible: :all).length).to eq(9)
      expect(page.text(:all)).to include("Osaka")
    end

    it "needs no disclosure when everything fits" do
      render_sites([site(city: "Birmingham", state: "Alabama"), site(city: "Mobile", state: "Alabama")])

      expect(page).to have_no_css("details")
    end
  end

  # Industry sponsors name every site the same thing, so 67 rows led with an
  # identical bold line and the one distinguishing fact sat underneath it.
  describe "when a sponsor names every site the same" do
    let(:sponsor_sites) do
      [site(city: "Birmingham", state: "Alabama", facility: "GSK Investigational Site"),
        site(city: "Mobile", state: "Alabama", facility: "GSK Investigational Site")]
    end

    it "leads with the place instead" do
      render_sites(sponsor_sites)

      first = page.all("li").first
      expect(first.all("span")[1].text.strip).to start_with("Birmingham")
      expect(first.text).to include("GSK Investigational Site")
    end

    it "still leads with a name that tells two sites apart" do
      render_sites([site(city: "Birmingham", state: "Alabama", facility: "UAB Hospital"),
        site(city: "Mobile", state: "Alabama", facility: "Mobile Infirmary")])

      expect(page.all("li").first.all("span")[1].text.strip).to eq("UAB Hospital")
    end
  end

  # The whole point of the coordinates the client now keeps, and the first thing
  # ever to read willing_travel_miles, which onboarding has asked for since it
  # was written.
  describe "with a profile that has a postal code" do
    let(:located) do
      ZipCode.create!(zip: "35203", city: "Birmingham", state: "Alabama", lat: 33.521, lon: -86.8066)
      create(:user).profile.tap { |p| p.update_columns(zip_code: "35203", state: "Alabama", willing_travel_miles: 50) }
    end

    def with_coords(city:, lat:, lon:, state: "Alabama")
      site(city: city, state: state).merge(geo_point: {lat: lat, lon: lon})
    end

    let(:sites) do
      [with_coords(city: "Toronto", state: nil, lat: 43.6532, lon: -79.3832),
        with_coords(city: "Tuscaloosa", lat: 33.1969, lon: -87.5627),
        with_coords(city: "Birmingham", lat: 33.5045, lon: -86.8055)]
    end

    it "orders the sites by how far away they actually are" do
      render_sites(sites, with_profile: located)

      expect(page.all("li").map(&:text).join(" | ")).to match(/Birmingham.*Tuscaloosa.*Toronto/m)
    end

    it "says how far each one is" do
      render_sites(sites, with_profile: located)

      expect(page.first("li").text).to match(/\d+ miles away/)
    end

    # Rounded to the mile: the registry gives a town centroid and the profile a
    # postal code centroid, so a tenth of a mile is precision neither end has.
    it "counts the ones inside the travel limit the profile was asked for" do
      render_sites(sites, with_profile: located)

      expect(page.text).to include("2 within the 50 miles you said you could travel")
    end

    # Two, because the summary is suppressed for a single site: with one row on
    # screen it would only repeat the miles the row already says.
    it "says none rather than going quiet when every site is too far" do
      render_sites([with_coords(city: "Toronto", state: nil, lat: 43.6532, lon: -79.3832),
        with_coords(city: "Osaka", state: nil, lat: 34.6937, lon: 135.5023)], with_profile: located)

      expect(page.text).to include("None within the 50 miles you said you could travel")
    end

    # Unknown is not nearby. A site the registry gave no point for sorts last
    # rather than first.
    it "puts a site with no coordinates after the ones it could measure" do
      render_sites(sites + [site(city: "Nowhere", state: "Alabama")], with_profile: located)

      expect(page.all("li").last.text).to include("Nowhere")
    end
  end

  it "offers directions rather than a distance it cannot compute" do
    render_sites([site(city: "Birmingham", state: "Alabama", facility: "UAB Hospital")])

    expect(page).to have_link("Directions", href: /google\.com\/maps.*UAB\+Hospital/)
    expect(page.text).not_to match(/\d+\s*mi\b/)
  end

  it "falls back to the plain location list when the registry gave no detail" do
    render_inline(described_class.new(study: {locations: ["Birmingham, Alabama"]}))

    expect(page.text).to include("Birmingham, Alabama")
  end

  it "renders nothing when the registry named no site" do
    render_inline(described_class.new(study: {}))

    expect(page.text.strip).to be_empty
  end
end
