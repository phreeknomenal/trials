require "csv"

# Loads the US zip lookup from db/seeds/zip_codes.csv.
#
# Source: GeoNames (https://download.geonames.org/export/zip/US.zip), licensed
# CC BY 4.0. APO/FPO military rows carry no state and were dropped, which also
# removed the only two duplicate zips in the set.
class Seeds::Record::ZipCode
  CSV_PATH = Rails.root.join("db/seeds/zip_codes.csv")
  BATCH_SIZE = 5_000

  class << self
    def seed
      import_zip_codes
      backfill_profile_locations
    end

    private

    # Skips entirely once the table is populated, because this runs on every
    # Heroku release and re-upserting 40k rows on each deploy buys nothing.
    # To pick up a refreshed CSV, truncate the table and reseed.
    def import_zip_codes
      return if ::ZipCode.exists?

      ActiveRecord::Base.transaction do
        rows.each_slice(BATCH_SIZE) do |slice|
          ::ZipCode.import(%i[zip city state], slice, validate: false, timestamps: true)
        end
      end
    end

    # Profiles resolve city and state from their zip on save, but existing rows
    # were written before that callback existed and would stay blank until their
    # owner happened to edit something.
    #
    # This lives in the seeder rather than in a migration because it needs the
    # lookup table populated, and the release phase runs db:prepare before
    # db:seed. A migration would run against an empty table.
    def backfill_profile_locations
      Profile.where(city: nil).or(Profile.where(state: nil))
        .where.not(zip_code: nil)
        .find_each do |profile|
          match = ::ZipCode.lookup(profile.zip_code)
          next if match.nil?

          profile.update_columns(
            city: profile.city.presence || match.city,
            state: profile.state.presence || match.state
          )
        end
    end

    def rows
      CSV.read(CSV_PATH, headers: true).map { |row| [row["zip"], row["city"], row["state"]] }
    end
  end
end
