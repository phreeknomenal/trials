# == Schema Information
#
# Table name: profiles
#
#  id                      :bigint           not null, primary key
#  birth_year              :integer
#  city                    :string
#  contact_preference      :string
#  country                 :string           default("US")
#  current_treatment       :string
#  diagnosis_timing        :string
#  ethnicity               :string           default("prefer not to say")
#  first_name              :string
#  language_preference     :string
#  last_name               :string
#  onboarded               :boolean          default(FALSE), not null
#  onboarding_step         :integer          default(1), not null
#  phone_number            :string
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
#  gender_id               :bigint
#  race_id                 :bigint
#  user_id                 :bigint           not null
#
# Indexes
#
#  index_profiles_on_gender_id  (gender_id)
#  index_profiles_on_race_id    (race_id)
#  index_profiles_on_user_id    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (gender_id => genders.id)
#  fk_rails_...  (race_id => races.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :profile do
    first_name { "Dana" }
    last_name { "Whitfield" }
    zip_code { "35201" }
    city { "Birmingham" }
    state { "Alabama" }
    birth_year { 40.years.ago.year }

    # Most specs want someone who can actually use the app. ApplicationController
    # redirects anyone mid-wizard, so an un-onboarded default would send every
    # request spec to /onboarding.
    onboarded { true }
    onboarding_step { Onboarding.complete_number }

    # User#add_default_profile builds a profile on create, and Profile validates
    # uniqueness of :user. Associating a fresh user here would give that user two
    # profiles and fail validation, so reuse the one it already has.
    initialize_with { create(:user).profile }

    # A profile as it exists the moment someone signs up: persisted by the User
    # callback and otherwise empty. Saved without validation because the record
    # is already persisted, so FactoryBot's save! would run the :update context
    # and reject exactly the blank fields this trait exists to represent.
    trait :onboarding do
      onboarded { false }
      onboarding_step { 1 }
      first_name { nil }
      last_name { nil }
      zip_code { nil }
      city { nil }
      state { nil }
      birth_year { nil }

      to_create { |profile| profile.save!(validate: false) }
    end

    # Part-way through the wizard. Pass the step number you want to land on.
    trait :mid_onboarding do
      transient { step { 3 } }

      onboarded { false }
      onboarding_step { step }
      zip_code { nil }
      city { nil }
      state { nil }

      to_create { |profile| profile.save!(validate: false) }
    end
  end
end
