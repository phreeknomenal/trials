require "rails_helper"

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
RSpec.describe Profile do
  describe "sex assigned at birth" do
    # Rejecting a value the form no longer offers matters because the scorer
    # reads this field as a hard gate. A stray "intersex" or "prefer not to say"
    # row would be disqualified from every sex-restricted trial.
    it "accepts the offered sexes" do
      Profile::SEX_ASSIGNED_AT_BIRTH_OPTIONS.each do |sex|
        expect(build(:profile, sex_assigned_at_birth: sex)).to be_valid
      end
    end

    it "accepts a blank value, which is how a user declines to answer" do
      expect(build(:profile, sex_assigned_at_birth: nil)).to be_valid
    end

    it "rejects values that were removed from the offered list" do
      ["intersex", "prefer not to say"].each do |removed|
        profile = build(:profile, sex_assigned_at_birth: removed)

        expect(profile).not_to be_valid
        expect(profile.errors[:sex_assigned_at_birth]).to be_present
      end
    end

    # PREFER_NOT_TO_SAY stays defined because ethnicity still uses it and
    # defaults to it. Only the sex list dropped it.
    it "keeps prefer not to say available for ethnicity" do
      expect(Profile::ETHNICITY_OPTIONS).to include(Profile::PREFER_NOT_TO_SAY)
      expect(Profile::SEX_ASSIGNED_AT_BIRTH_OPTIONS).not_to include(Profile::PREFER_NOT_TO_SAY)
    end
  end

  describe "resolving city and state from zip" do
    before { create(:zip_code, zip: "44106", city: "Cleveland", state: "Ohio") }

    it "fills a blank city and state from the zip" do
      profile = create(:profile)
      profile.update!(zip_code: "44106", city: nil, state: nil)

      expect(profile.city).to eq("Cleveland")
      expect(profile.state).to eq("Ohio")
    end

    it "resolves a ZIP+4" do
      profile = create(:profile)
      profile.update!(zip_code: "44106-1234", city: nil, state: nil)

      expect(profile.city).to eq("Cleveland")
    end

    # The full edit form exposes city and state, so a hand-typed value has to
    # win over the lookup.
    it "does not overwrite a city the user typed" do
      profile = create(:profile)
      profile.update!(zip_code: "44106", city: "Shaker Heights", state: "Ohio")

      expect(profile.city).to eq("Shaker Heights")
    end

    it "fills only the half that is blank" do
      profile = create(:profile)
      profile.update!(zip_code: "44106", city: "Shaker Heights", state: nil)

      expect(profile.city).to eq("Shaker Heights")
      expect(profile.state).to eq("Ohio")
    end

    # Someone who moves updates their zip and expects the rest to follow.
    it "re-resolves both when the zip changes on its own" do
      create(:zip_code, zip: "35203", city: "Birmingham", state: "Alabama")
      profile = create(:profile)
      profile.update!(zip_code: "44106", city: nil, state: nil)

      profile.update!(zip_code: "35203")

      expect(profile.city).to eq("Birmingham")
      expect(profile.state).to eq("Alabama")
    end

    it "leaves a city the user changed alongside the zip" do
      create(:zip_code, zip: "35203", city: "Birmingham", state: "Alabama")
      profile = create(:profile)
      profile.update!(zip_code: "44106", city: nil, state: nil)

      profile.update!(zip_code: "35203", city: "Homewood")

      expect(profile.city).to eq("Homewood")
    end

    it "leaves the profile alone for an unknown zip" do
      profile = create(:profile)
      profile.update!(zip_code: "99999", city: nil, state: nil)

      expect(profile.city).to be_nil
      expect(profile.state).to be_nil
    end

    it "is a no-op when there is no zip" do
      profile = build(:profile, zip_code: nil, city: nil, state: nil)

      expect { profile.valid? }.not_to raise_error
      expect(profile.city).to be_nil
    end
  end
end
