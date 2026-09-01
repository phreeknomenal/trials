require "rails_helper"

RSpec.describe Seeds::Record::ZipCode do
  describe ".seed" do
    # The release phase runs db:seed on every deploy, so this has to be safe to
    # run against an already-populated table.
    it "does not duplicate rows when run twice" do
      described_class.seed
      first = ZipCode.count

      described_class.seed

      expect(ZipCode.count).to eq(first)
      expect(first).to be > 40_000
    end

    it "loads full state names, which is what trial locations carry" do
      described_class.seed

      expect(ZipCode.lookup("44106")).to have_attributes(city: "Cleveland", state: "Ohio")
      expect(ZipCode.lookup("35203")).to have_attributes(city: "Birmingham", state: "Alabama")
    end

    # Profiles written before the resolution callback existed would otherwise
    # stay blank until their owner happened to edit something. This cannot be a
    # migration: the release phase runs db:prepare before db:seed, so the
    # lookup table is still empty when migrations run.
    # Seeding an existing row first exercises the early return in
    # import_zip_codes and keeps these two examples off the 40k-row CSV.
    it "backfills profiles that have a zip but no city or state" do
      create(:zip_code, zip: "44106", city: "Cleveland", state: "Ohio")
      profile = create(:profile)
      profile.update_columns(zip_code: "44106", city: nil, state: nil)

      described_class.seed

      expect(profile.reload).to have_attributes(city: "Cleveland", state: "Ohio")
    end

    it "leaves a profile's existing city alone" do
      create(:zip_code, zip: "44106", city: "Cleveland", state: "Ohio")
      profile = create(:profile)
      profile.update_columns(zip_code: "44106", city: "Shaker Heights", state: nil)

      described_class.seed

      expect(profile.reload).to have_attributes(city: "Shaker Heights", state: "Ohio")
    end
  end
end
