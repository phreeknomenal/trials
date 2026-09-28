require "rails_helper"

RSpec.describe Distance do
  # Checked against published straight-line distances. Haversine's error against
  # the real geoid is well under half a percent, which every question this
  # answers can absorb: "is this site within the sixty miles you said".
  describe ".between" do
    let(:birmingham) { [33.5207, -86.8025] }

    it "measures a short hop" do
      expect(described_class.between(birmingham, [33.5045, -86.8055])).to be_within(0.5).of(1.1)
    end

    it "measures across a state" do
      expect(described_class.between(birmingham, [33.1969, -87.5627])).to be_within(1).of(49)
    end

    it "measures across a border" do
      expect(described_class.between(birmingham, [43.6532, -79.3832])).to be_within(5).of(806)
    end

    it "is zero from a point to itself" do
      expect(described_class.between(birmingham, birmingham)).to eq(0.0)
    end

    it "does not care which way round the two points are" do
      there = described_class.between(birmingham, [43.6532, -79.3832])
      back = described_class.between([43.6532, -79.3832], birmingham)

      expect(there).to eq(back)
    end
  end

  # Unknown is the normal case, not an error: a profile may carry no postal
  # code, and 2% of registry locations publish no coordinates.
  describe "when either end is unknown" do
    it "is nil without a start" do
      expect(described_class.between(nil, [33.5, -86.8])).to be_nil
    end

    it "is nil without an end" do
      expect(described_class.between([33.5, -86.8], nil)).to be_nil
    end

    it "is nil when a record has no coordinates" do
      expect(described_class.between(ZipCode.new(zip: "35203"), [33.5, -86.8])).to be_nil
    end
  end

  # So callers do not each unpack the registry's shape themselves.
  describe "the shapes it accepts" do
    it "takes the registry's hash" do
      expect(described_class.between({lat: 33.5207, lon: -86.8025}, [33.1969, -87.5627]))
        .to be_within(1).of(49)
    end

    it "takes string keys, which is how a captured payload arrives" do
      expect(described_class.between({"lat" => 33.5207, "lon" => -86.8025}, [33.1969, -87.5627]))
        .to be_within(1).of(49)
    end

    it "takes anything that answers to coordinates" do
      zip = ZipCode.new(zip: "35203", city: "Birmingham", state: "Alabama", lat: 33.5207, lon: -86.8025)

      expect(described_class.between(zip, [33.1969, -87.5627])).to be_within(1).of(49)
    end
  end
end
