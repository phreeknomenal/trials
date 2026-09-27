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
