# == Schema Information
#
# Table name: zip_codes
#
#  id         :bigint           not null, primary key
#  city       :string           not null
#  lat        :decimal(8, 4)
#  lon        :decimal(9, 4)
#  state      :string           not null
#  zip        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_zip_codes_on_zip  (zip) UNIQUE
#

# Static US postal lookup. Read-only in practice: rows come from
# db/seeds/zip_codes.csv and nothing in the app writes to this table.
class ZipCode < ApplicationRecord
  validates :zip, presence: true, uniqueness: true
  validates :city, presence: true
  validates :state, presence: true

  # Accepts what people actually type: "35203", "35203-1234", " 35203 ".
  # Returns nil when there is no five-digit zip in the input at all.
  def self.canonical(value)
    digits = value.to_s.gsub(/\D/, "")
    return nil if digits.length < 5

    digits.first(5)
  end

  def self.lookup(value)
    zip = canonical(value)
    return nil if zip.nil?

    find_by(zip: zip)
  end

  # The point Distance measures from. Nil rather than a pair of zeroes, which
  # is a real place in the Gulf of Guinea and would put every study 5,000 miles
  # away rather than an unknown distance away.
  def coordinates
    return nil if lat.nil? || lon.nil?

    [lat.to_f, lon.to_f]
  end
end
