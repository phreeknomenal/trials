FactoryBot.define do
  factory :profile do
    first_name { "Dana" }
    last_name { "Whitfield" }
    zip_code { "35201" }
    city { "Birmingham" }
    state { "Alabama" }
    birth_year { 40.years.ago.year }

    # User#add_default_profile builds a profile on create, and Profile validates
    # uniqueness of :user. Associating a fresh user here would give that user two
    # profiles and fail validation, so reuse the one it already has.
    initialize_with { create(:user).profile }
  end
end
