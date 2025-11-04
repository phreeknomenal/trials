# == Schema Information
#
# Table name: profiles
#
#  id                      :integer          not null, primary key
#  birth_year              :integer
#  city                    :string
#  condition_subtype       :string
#  contact_preference      :string
#  country                 :string           default("US")
#  current_treatment       :string
#  diagnosis_timing        :string
#  first_name              :string
#  language_preference     :string
#  last_name               :string
#  onboarded               :boolean          default(FALSE), not null
#  phone_number            :string
#  primary_condition       :string
#  prior_treatment         :boolean          default(FALSE)
#  pronouns                :string
#  remote_visit_preference :string
#  risk_tolerance          :string
#  sex_assigned_at_birth   :string
#  state                   :string
#  transportation_reliable :boolean          default(TRUE)
#  trial_type_preference   :string
#  willing_travel_miles    :integer
#  zip_code                :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  gender_id               :integer
#  race_id                 :integer
#  user_id                 :integer          not null
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

require "test_helper"

class ProfileTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
