# == Schema Information
#
# Table name: profile_conditions
#
#  id           :bigint           not null, primary key
#  is_primary   :boolean          default(FALSE)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  condition_id :bigint           not null
#  profile_id   :bigint           not null
#
# Indexes
#
#  index_profile_conditions_on_condition_id                 (condition_id)
#  index_profile_conditions_on_profile_id                   (profile_id)
#  index_profile_conditions_on_profile_id_and_condition_id  (profile_id,condition_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (condition_id => conditions.id)
#  fk_rails_...  (profile_id => profiles.id)
#
class ProfileCondition < ApplicationRecord
  belongs_to :profile
  belongs_to :condition

  validates :condition_id, uniqueness: {scope: :profile_id}
  validate :profile_id_not_updated
  validate :condition_id_not_updated
  validate :only_one_primary_condition

  private

  def profile_id_not_updated
    if profile_id_changed? && persisted?
      errors.add(:profile_id, "can't be updated")
    end
  end

  def condition_id_not_updated
    if condition_id_changed? && persisted?
      errors.add(:condition_id, "can't be updated")
    end
  end

  def only_one_primary_condition
    if is_primary? && persisted? && is_primary_changed?
      if profile.profile_conditions.where(is_primary: true).where.not(id: id).exists?
        errors.add(:is_primary, "can only have one primary condition")
      end
    elsif is_primary? && !persisted?
      if profile.profile_conditions.where(is_primary: true).exists?
        errors.add(:is_primary, "can only have one primary condition")
      end
    end
  end
end
