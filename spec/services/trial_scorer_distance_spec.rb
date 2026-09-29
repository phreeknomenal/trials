require "rails_helper"

# score_location was a string match on city and state: a site four miles away
# and one three hundred miles away in the same state both scored 75, and
# everything outside the state scored the same flat number whether it was in
# the next county or in Osaka. It is 15% of every match score.
RSpec.describe TrialScorer, "scoring location by distance" do
  let(:profile) do
    ZipCode.create!(zip: "35203", city: "Birmingham", state: "Alabama", lat: 33.521, lon: -86.8066)
    create(:user).profile.tap do |p|
      p.update_columns(zip_code: "35203", city: "Birmingham", state: "Alabama",
        birth_year: 1985, willing_travel_miles: 50)
    end
  end

  def site(lat, lon) = {display: "A site", geo_point: {lat: lat, lon: lon}}

  def location_score(*sites, **profile_attrs)
    profile.update_columns(profile_attrs) if profile_attrs.any?
    trial = {locations_detailed: sites, locations: ["Somewhere"]}

    described_class.new(profile, trial).send(:score_location)
  end

  it "gives full marks inside the distance the profile said it could travel" do
    expect(location_score(site(33.5045, -86.8055))).to eq(100)
  end

  it "still gives full marks at the edge of that distance" do
    # Tuscaloosa is 49 miles from downtown Birmingham, inside a 50 mile limit.
    expect(location_score(site(33.1969, -87.5627))).to eq(100)
  end

  it "falls away beyond it rather than dropping to a flat number" do
    near = location_score(site(33.1969, -87.5627))   # 49 mi
    mid = location_score(site(32.3668, -86.3000))    # Montgomery, ~88 mi
    far = location_score(site(43.6532, -79.3832))    # Toronto, ~806 mi

    expect(near).to be > mid
    expect(mid).to be > far
  end

  it "never goes below zero, however far away the study is" do
    expect(location_score(site(-33.8688, 151.2093))).to eq(0)
  end

  # A study with one site five miles away and sixty across the country is a
  # five mile study for this person.
  it "scores the nearest site, not the first one listed" do
    score = location_score(site(43.6532, -79.3832), site(33.5045, -86.8055))

    expect(score).to eq(100)
  end

  it "assumes the middle of the four options when the profile never answered" do
    expect(location_score(site(33.1969, -87.5627), willing_travel_miles: nil)).to eq(100)
  end

  # A profile with no postal code scores exactly as it did before.
  describe "when there is no distance to be had" do
    it "falls back to the city match" do
      profile.update_columns(zip_code: nil)
      trial = {locations: ["Birmingham, Alabama"], locations_detailed: []}

      expect(described_class.new(profile, trial).send(:score_location)).to eq(100)
    end

    it "falls back to the state match" do
      profile.update_columns(zip_code: nil)
      trial = {locations: ["Mobile, Alabama"], locations_detailed: []}

      expect(described_class.new(profile, trial).send(:score_location)).to eq(75)
    end

    it "falls back to the travel-willingness proxy for anywhere else" do
      profile.update_columns(zip_code: nil)
      trial = {locations: ["Toronto, Ontario"], locations_detailed: []}

      expect(described_class.new(profile, trial).send(:score_location)).to eq(35)
    end

    it "is neutral when the study published no location at all" do
      trial = {locations: [], locations_detailed: []}

      expect(described_class.new(profile, trial).send(:score_location)).to eq(50)
    end
  end
end
