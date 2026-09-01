# A static US zip to city/state lookup, seeded from db/seeds/zip_codes.csv.
#
# score_location compares place names against a trial's location components
# ("Cleveland, Ohio, United States"), so this stores full state names rather
# than abbreviations. No coordinates: nothing measures distance yet, and
# willing_travel_miles is read as a willingness proxy rather than a radius.
class CreateZipCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :zip_codes do |t|
      t.string :zip, null: false
      t.string :city, null: false
      t.string :state, null: false

      t.timestamps
    end

    add_index :zip_codes, :zip, unique: true
  end
end
