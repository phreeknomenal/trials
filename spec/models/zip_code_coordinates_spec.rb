require "rails_helper"

RSpec.describe ZipCode do
  describe "#coordinates" do
    it "gives the point the zip sits on" do
      zip = described_class.new(zip: "35203", city: "Birmingham", state: "Alabama",
        lat: 33.521, lon: -86.8066)

      expect(zip.coordinates).to eq([33.521, -86.8066])
    end

    # Not [0, 0], which is a real place in the Gulf of Guinea and would put
    # every study five thousand miles away rather than an unknown distance away.
    it "is nil rather than the origin when the row has none" do
      expect(described_class.new(zip: "35203").coordinates).to be_nil
    end
  end
end
