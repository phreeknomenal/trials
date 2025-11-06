# == Schema Information
#
# Table name: conditions
#
#  id         :integer          not null, primary key
#  name       :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_conditions_on_name  (name) UNIQUE
#
class Condition < ApplicationRecord
  has_many :profile_conditions, dependent: :destroy
  has_many :profiles, through: :profile_conditions

  validates :name, presence: true, uniqueness: true
end
