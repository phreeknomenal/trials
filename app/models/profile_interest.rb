# == Schema Information
#
# Table name: profile_interests
#
#  id          :integer          not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  interest_id :integer          not null
#  profile_id  :integer          not null
#
# Indexes
#
#  index_profile_interests_on_interest_id                 (interest_id)
#  index_profile_interests_on_profile_id                  (profile_id)
#  index_profile_interests_on_profile_id_and_interest_id  (profile_id,interest_id) UNIQUE
#
# Foreign Keys
#
#  interest_id  (interest_id => interests.id)
#  profile_id   (profile_id => profiles.id)
#
class ProfileInterest < ApplicationRecord
  belongs_to :profile
  belongs_to :interest

  validates :interest_id, uniqueness: { scope: :profile_id }
  validate :profile_id_not_updated
  validate :interest_id_not_updated

  private

  def profile_id_not_updated
    if profile_id_changed? && persisted?
      errors.add(:profile_id, "can't be updated")
    end
  end

  def interest_id_not_updated
    if interest_id_changed? && persisted?
      errors.add(:interest_id, "can't be updated")
    end
  end
end
