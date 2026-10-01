require "rails_helper"

# Step 4 of Tasks/trials-location-distance.md. The registry narrows by radius
# itself, so a page of ten is ten studies somebody can reach rather than ten it
# happened to rank first. Filtering after the fetch cannot work: the registry
# does not know what was dropped, so page two would repeat page one's gaps.
RSpec.describe "Searching within a radius" do
  describe ClinicalTrialClient, ".geo_filter" do
    it "builds the registry's own distance filter" do
      expect(described_class.geo_filter(50, [33.521, -86.8066])).to eq("distance(33.521,-86.8066,50mi)")
    end

    # Dropping the key searches the whole registry, which is the right failure:
    # a radius nobody can anchor should widen the search, never empty it.
    it "is nil without a point to measure from" do
      expect(described_class.geo_filter(50, nil)).to be_nil
      expect(described_class.geo_filter(50, [nil, nil])).to be_nil
    end

    it "is nil without a radius" do
      expect(described_class.geo_filter(nil, [33.521, -86.8066])).to be_nil
      expect(described_class.geo_filter(0, [33.521, -86.8066])).to be_nil
    end
  end

  describe TrialSearchService, "choosing where to measure from" do
    let(:profile) do
      ZipCode.create!(zip: "35203", city: "Birmingham", state: "Alabama", lat: 33.521, lon: -86.8066)
      ZipCode.create!(zip: "60601", city: "Chicago", state: "Illinois", lat: 41.8858, lon: -87.6229)
      create(:user).profile.tap { |p| p.update_columns(zip_code: "35203") }
    end

    def origin_for(location)
      described_class.new(profile: profile, search_params: {condition: "asthma", location: location, within_miles: 50})
        .send(:origin)
    end

    # Someone searching Chicago while living in Birmingham means Chicago.
    it "measures from the zip that was searched for, over the profile's" do
      expect(origin_for("60601")).to eq([41.8858, -87.6229])
    end

    it "measures from the profile when no location was typed at all" do
      expect(origin_for(nil)).to eq([33.521, -86.8066])
    end

    # Measuring it from the profile instead would silently answer a different
    # question: fifty miles from Birmingham, for a search that said Chicago.
    it "anchors nothing to a typed place name, even with a profile to fall back on" do
      expect(origin_for("Chicago, IL")).to be_nil
    end

    # So the page can say so rather than quietly returning the whole registry.
    it "reports a radius it could not anchor" do
      profile.update_columns(zip_code: nil)
      service = described_class.new(profile: profile,
        search_params: {condition: "asthma", location: "Chicago, IL", within_miles: 50})

      expect(service.send(:radius_unanchored?)).to be(true)
    end

    # query.locn is a place-name match: "35203" returns nothing at all while
    # "Birmingham, Alabama" returns four, and the field has invited a zip since
    # it was written.
    describe "a typed postal code" do
      def resolved_for(location, within_miles: nil)
        described_class.new(profile: profile,
          search_params: {condition: "asthma", location: location, within_miles: within_miles}.compact)
          .send(:resolved_location)
      end

      it "becomes the town the registry can actually match" do
        expect(resolved_for("35203")).to eq("Birmingham, Alabama")
      end

      it "gives way to the radius when one was chosen" do
        expect(resolved_for("35203", within_miles: 50)).to be_nil
      end

      it "leaves a place name alone" do
        expect(resolved_for("Chicago, IL")).to eq("Chicago, IL")
      end
    end

    it "reports nothing wrong when no radius was asked for" do
      service = described_class.new(profile: profile, search_params: {condition: "asthma"})

      expect(service.send(:radius_unanchored?)).to be(false)
    end
  end
end
