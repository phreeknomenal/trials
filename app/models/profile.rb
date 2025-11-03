# == Schema Information
#
# Table name: profiles
#
#  id           :integer          not null, primary key
#  birth_date   :date
#  first_name   :string
#  last_name    :string
#  onboarded    :boolean          default(FALSE), not null
#  phone_number :string
#  pronouns     :string
#  zip_code     :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  gender_id    :integer
#  race_id      :integer
#  user_id      :integer          not null
#
# Indexes
#
#  index_profiles_on_gender_id  (gender_id)
#  index_profiles_on_race_id    (race_id)
#  index_profiles_on_user_id    (user_id)
#
# Foreign Keys
#
#  gender_id  (gender_id => genders.id)
#  race_id    (race_id => races.id)
#  user_id    (user_id => users.id)
#

class Profile < ApplicationRecord
  PRONOUN_OPTIONS = [ "he/him", "she/her", "they/them", "other" ]

  belongs_to :user
  belongs_to :gender, optional: true

  has_one_attached :avatar

  validates :user_id, uniqueness: true
  validates :onboarded, inclusion: [ true, false ]
  validates :first_name, presence: true, on: :update
  validates :last_name, presence: true, on: :update
  validates :zip_code, presence: true, on: :update
  validates :pronouns, inclusion: { in: PRONOUN_OPTIONS }, allow_blank: true

  def full_name
    "#{first_name} #{last_name}"
  end
end
