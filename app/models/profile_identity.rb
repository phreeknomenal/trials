# == Schema Information
#
# Table name: profile_identities
#
#  id          :bigint           not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  identity_id :integer          not null
#  profile_id  :integer          not null
#
# Indexes
#
#  index_profile_identities_on_identity_id                 (identity_id)
#  index_profile_identities_on_profile_id                  (profile_id)
#  index_profile_identities_on_profile_id_and_identity_id  (profile_id,identity_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (identity_id => identities.id)
#  fk_rails_...  (profile_id => profiles.id)
#
class ProfileIdentity < ApplicationRecord
  belongs_to :profile
  belongs_to :identity

  validates :identity_id, uniqueness: {scope: :profile_id}
  validate :profile_id_not_updated
  validate :identity_id_not_updated

  private

  def profile_id_not_updated
    if profile_id_changed? && persisted?
      errors.add(:profile_id, "can't be updated")
    end
  end

  def identity_id_not_updated
    if identity_id_changed? && persisted?
      errors.add(:identity_id, "can't be updated")
    end
  end
end
