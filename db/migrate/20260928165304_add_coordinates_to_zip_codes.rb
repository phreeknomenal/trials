# The zip lookup already held city and state from GeoNames and dropped the
# coordinates in the same row.
#
# Without them the app could not say how far away a study site is, so the study
# page ranked sites by a string match on US state, the scorer spent 15% of every
# match on that same string match, and willing_travel_miles was collected at
# onboarding and read by nothing. See Tasks/trials-location-distance.md.
class AddCoordinatesToZipCodes < ActiveRecord::Migration[8.1]
  def change
    add_column :zip_codes, :lat, :decimal, precision: 8, scale: 4
    add_column :zip_codes, :lon, :decimal, precision: 9, scale: 4
  end
end
