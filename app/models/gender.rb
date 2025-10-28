# == Schema Information
#
# Table name: genders
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_genders_on_name  (name) UNIQUE
#

class Gender < ApplicationRecord
  has_many :profiles, dependent: :destroy
end
