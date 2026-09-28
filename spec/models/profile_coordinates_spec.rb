require "rails_helper"

RSpec.describe Profile do
  describe "#coordinates" do
    let(:profile) { create(:user).profile }

    before { ZipCode.create!(zip: "35203", city: "Birmingham", state: "Alabama", lat: 33.521, lon: -86.8066) }

    it "reads the point off the profile's zip" do
      profile.update_columns(zip_code: "35203")

      expect(profile.coordinates).to eq([33.521, -86.8066])
    end

    it "takes a nine-digit zip, which is what people type" do
      profile.update_columns(zip_code: "35203-1234")

      expect(profile.coordinates).to eq([33.521, -86.8066])
    end

    it "is nil for a zip nothing knows about" do
      profile.update_columns(zip_code: "00000")

      expect(profile.coordinates).to be_nil
    end

    it "is nil when the profile gave no zip at all" do
      profile.update_columns(zip_code: nil)

      expect(profile.coordinates).to be_nil
    end
  end
end
