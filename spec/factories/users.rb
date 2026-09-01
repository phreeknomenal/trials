# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :string           default("member"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    role { "member" }

    # User#add_default_profile persists a blank profile at signup, which sits at
    # onboarding step 1 and which ApplicationController redirects to the wizard.
    # Specs that are not about onboarding want a user who can reach the app, so
    # the default is a finished profile. Use the :onboarding trait for a user
    # who has just signed up.
    after(:create) do |user|
      user.profile&.update_columns(
        first_name: "Dana",
        last_name: "Whitfield",
        zip_code: "35201",
        city: "Birmingham",
        state: "Alabama",
        birth_year: 40.years.ago.year,
        onboarded: true,
        onboarding_step: Onboarding.complete_number
      )
      user.association(:profile).reload
    end

    trait :onboarding do
      after(:create) do |user|
        user.profile&.update_columns(
          first_name: nil, last_name: nil, zip_code: nil, city: nil, state: nil,
          birth_year: nil, onboarded: false, onboarding_step: 1
        )
        user.association(:profile).reload
      end
    end
  end
end
