require "rails_helper"

# == Schema Information
#
# Table name: zip_codes
#
#  id         :bigint           not null, primary key
#  city       :string           not null
#  state      :string           not null
#  zip        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_zip_codes_on_zip  (zip) UNIQUE
#
RSpec.describe ZipCode do
  describe ".canonical" do
    it "accepts a plain five-digit zip" do
      expect(described_class.canonical("35203")).to eq("35203")
    end

    # The onboarding field caps input at five digits, but the full edit form
    # does not, and people paste ZIP+4.
    it "takes the first five digits of a ZIP+4" do
      expect(described_class.canonical("35203-1234")).to eq("35203")
    end

    it "ignores surrounding whitespace and punctuation" do
      expect(described_class.canonical("  35203  ")).to eq("35203")
    end

    it "is nil when there is no five-digit zip" do
      expect(described_class.canonical("352")).to be_nil
      expect(described_class.canonical("abcde")).to be_nil
      expect(described_class.canonical(nil)).to be_nil
      expect(described_class.canonical("")).to be_nil
    end
  end

  describe ".lookup" do
    it "finds a seeded zip" do
      create(:zip_code, zip: "44106", city: "Cleveland", state: "Ohio")

      expect(described_class.lookup("44106").city).to eq("Cleveland")
    end

    it "finds a zip written as ZIP+4" do
      create(:zip_code, zip: "44106", city: "Cleveland", state: "Ohio")

      expect(described_class.lookup("44106-0000").city).to eq("Cleveland")
    end

    it "is nil for an unknown zip" do
      expect(described_class.lookup("00000")).to be_nil
    end

    it "is nil for unusable input" do
      expect(described_class.lookup(nil)).to be_nil
      expect(described_class.lookup("abc")).to be_nil
    end
  end
end
