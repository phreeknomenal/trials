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

  # A select rendered with include_blank submits "", not nil, and score_sex
  # reads a present-but-empty value as an answer: it returned 0 rather than the
  # neutral 50, so declining to answer cost 20 points of weight.
  describe "blank optional fields" do
    it "stores a declined select as nil, not an empty string" do
      profile = create(:profile)
      profile.update!(sex_assigned_at_birth: "", risk_tolerance: "", trial_type_preference: "")

      expect(profile.reload).to have_attributes(
        sex_assigned_at_birth: nil, risk_tolerance: nil, trial_type_preference: nil
      )
    end

    it "scores a declined sex as neutral rather than as a mismatch" do
      profile = create(:profile)
      profile.update!(sex_assigned_at_birth: "")
      trial = {sex: "FEMALE", conditions: [], locations: [], phase: nil, status: "RECRUITING"}

      result = TrialScorer.new(profile.reload, trial)

      expect(result.send(:score_sex)).to eq(50)
      expect(result.calculate_score[:disqualifiers]).not_to include(:sex)
    end
  end

  describe "onboarding progress" do
    # The bug: a profile whose step fell below 1 made current_onboarding_step
    # return nil, and ensure_profile_completed called .slug on it. That crashed
    # every page, and the wizard was unreachable because it is reached through
    # that same redirect.
    #
    # This is the exact property the gate depends on: for any integer the column
    # can hold, either the app is unlocked or there is a step to send them to.
    # Never both false.
    it "always yields a step to redirect to when the app is still locked" do
      (-5..Onboarding.complete_number + 3).each do |value|
        profile = build(:profile, onboarding_step: value)

        has_somewhere_to_go = profile.onboarding_unlocked? || profile.current_onboarding_step.present?

        expect(has_somewhere_to_go).to be(true),
          "onboarding_step #{value} leaves the gate with nowhere to redirect, which crashes every page"
      end
    end

    it "clamps a step below the wizard range back to the first step" do
      expect(build(:profile, onboarding_step: 0).current_onboarding_step).to eq(Onboarding.first)
      expect(build(:profile, onboarding_step: -3).current_onboarding_step).to eq(Onboarding.first)
    end

    it "treats a step past the last one as finished" do
      profile = build(:profile, onboarding_step: Onboarding.complete_number + 5)

      expect(profile).to be_profile_completed
      expect(profile.current_onboarding_step).to be_nil
    end

    it "does not report a locked profile as unlocked" do
      expect(build(:profile, onboarding_step: 0)).not_to be_onboarding_unlocked
    end

    # ActiveRecord casts a non-numeric assignment to 0 rather than rejecting it,
    # which is how a value below the wizard range becomes storable at all.
    it "rejects a non-numeric step that would silently cast to zero" do
      profile = build(:profile, onboarding_step: "abc")

      expect(profile.onboarding_step).to eq(0)
      expect(profile).not_to be_valid
      expect(profile.errors[:onboarding_step]).to be_present
    end

    it "rejects a step below one" do
      expect(build(:profile, onboarding_step: 0)).not_to be_valid
    end

    # update_column and raw SQL skip validations, and the wizard advances
    # progress with update_column, so the database has to enforce this too.
    it "refuses a below-range write that bypasses validations" do
      profile = create(:profile)

      expect {
        profile.update_column(:onboarding_step, 0)
      }.to raise_error(ActiveRecord::StatementInvalid, /check constraint/i)
    end
  end
end
