# == Schema Information
#
# Table name: races
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_races_on_name  (name) UNIQUE
#

class Race < ApplicationRecord
  has_many :profiles, dependent: :destroy
end
