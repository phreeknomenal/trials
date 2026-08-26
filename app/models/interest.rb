# == Schema Information
#
# Table name: interests
#
#  id         :bigint           not null, primary key
#  name       :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_interests_on_name  (name) UNIQUE
#
class Interest < ApplicationRecord
  has_many :profile_interests, dependent: :destroy
  has_many :profiles, through: :profile_interests

  validates :name, presence: true, uniqueness: true
end
