require "rails_helper"

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
end
