# == Schema Information
#
# Table name: identities
#
#  id         :bigint           not null, primary key
#  name       :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_identities_on_name  (name) UNIQUE
#
class Identity < ApplicationRecord
  has_many :profile_identities, dependent: :destroy
  has_many :profiles, through: :profile_identities

  validates :name, presence: true, uniqueness: true
end
