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
FactoryBot.define do
  factory :zip_code do
    sequence(:zip) { |n| format("%05d", 10000 + n) }
    city { "Birmingham" }
    state { "Alabama" }
  end
end
