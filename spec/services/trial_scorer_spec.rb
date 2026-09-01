require "rails_helper"

RSpec.describe TrialScorer do
  let(:profile) { create(:profile) }

  def scorer(trial, for_profile: profile)
    described_class.new(for_profile, trial)
  end

  describe "#parse_age" do
    subject(:parse) { ->(value) { scorer({}).send(:parse_age, value) } }

    it "reads a value in years" do
      expect(parse.call("18 Years")).to eq(18.0)
    end

    it "treats a bare number as years" do
      expect(parse.call("21")).to eq(21.0)
    end

    it "returns nil for nil" do
      expect(parse.call(nil)).to be_nil
    end

    it "returns nil when there is no number" do
      expect(parse.call("N/A")).to be_nil
    end

    # ClinicalTrials.gov uses "6 Months" and "30 Days" for paediatric and
    # neonatal limits. Reading the number alone made these 6 and 30 YEARS.
    it "converts months to years" do
      expect(parse.call("6 Months")).to be_within(0.001).of(0.5)
    end

    it "converts days to years" do
      expect(parse.call("30 Days")).to be_within(0.001).of(30 / 365.25)
    end

    it "converts weeks to years" do
      expect(parse.call("52 Weeks")).to be_within(0.01).of(1.0)
    end

    it "does not treat 6 Months as 6 years" do
      expect(parse.call("6 Months")).to be < 1
    end
  end

  describe "#score_age" do
    def age_score(min:, max:, birth_year:)
      p = create(:profile, birth_year: birth_year)
      scorer({min_age: min, max_age: max}, for_profile: p).send(:score_age)
    end

    it "scores 100 with no age limits" do
      expect(age_score(min: nil, max: nil, birth_year: 40.years.ago.year)).to eq(100)
    end

    it "scores 100 inside the range" do
      expect(age_score(min: "18 Years", max: "65 Years", birth_year: 40.years.ago.year)).to eq(100)
    end

    it "scores 0 below the minimum" do
      expect(age_score(min: "18 Years", max: nil, birth_year: 10.years.ago.year)).to eq(0)
    end

    it "scores 0 above the maximum" do
      expect(age_score(min: nil, max: "65 Years", birth_year: 80.years.ago.year)).to eq(0)
    end

    # Regression: with the old parser this trial required a minimum of 6 YEARS,
    # so a 2-year-old was excluded from a study open from 6 months of age.
    it "includes a toddler in a trial open from 6 months" do
      expect(age_score(min: "6 Months", max: "17 Years", birth_year: 2.years.ago.year)).to eq(100)
    end

    it "scores neutral when the profile has no age" do
      p = create(:profile, birth_year: nil)
      expect(scorer({min_age: "18 Years"}, for_profile: p).send(:score_age)).to eq(50)
    end
  end

  describe "#conditions_match?" do
    subject(:matches) { ->(pc, tc) { scorer({}).send(:conditions_match?, pc, tc) } }

    it "matches an identical condition" do
      expect(matches.call("asthma", "asthma")).to be(true)
    end

    it "matches a specific profile condition against a broader trial condition" do
      expect(matches.call("lung cancer", "cancer")).to be(true)
    end

    it "matches a broad profile condition against a specific trial condition" do
      expect(matches.call("cancer", "lung cancer")).to be(true)
    end

    it "matches across extra qualifiers" do
      expect(matches.call("type 2 diabetes", "diabetes")).to be(true)
    end

    it "does not match two different cancers" do
      expect(matches.call("breast cancer", "lung cancer")).to be(false)
    end

    # Regression: a bare substring check matched any abbreviation appearing
    # inside a longer word. Both MS and ALS are in the seeded condition list.
    it "does not match ms against symptoms" do
      expect(matches.call("ms", "symptoms")).to be(false)
    end

    it "does not match als against false positives" do
      expect(matches.call("als", "false positives")).to be(false)
    end

    it "returns false for blank input" do
      expect(matches.call("", "cancer")).to be(false)
      expect(matches.call("cancer", "")).to be(false)
    end
  end

  describe "#score_conditions" do
    def condition_score(profile_conditions, trial_conditions)
      p = create(:profile)
      profile_conditions.each { |name| p.conditions << Condition.find_or_create_by!(name: name) }
      scorer({conditions: trial_conditions}, for_profile: p.reload).send(:score_conditions)
    end

    it "scores 100 when every profile condition matches" do
      expect(condition_score(["asthma"], ["Asthma"])).to eq(100)
    end

    it "scores 0 when none match" do
      expect(condition_score(["asthma"], ["Diabetes"])).to eq(0)
    end

    it "scores partially when some match" do
      expect(condition_score(["asthma", "diabetes"], ["Asthma"])).to eq(50)
    end

    it "scores neutral when the profile has no conditions" do
      expect(condition_score([], ["Asthma"])).to eq(50)
    end

    # Regression at the scoring level, not just the helper.
    it "does not credit a symptoms trial for a profile listing ms" do
      expect(condition_score(["ms"], ["Symptoms"])).to eq(0)
    end
  end

  describe "#location_component?" do
    subject(:matches) { ->(loc, value) { scorer({}).send(:location_component?, loc, value) } }

    it "matches a city component" do
      expect(matches.call("Birmingham, Alabama, United States", "Birmingham")).to be(true)
    end

    it "matches a state component" do
      expect(matches.call("Birmingham, Alabama, United States", "Alabama")).to be(true)
    end

    it "ignores case and surrounding whitespace" do
      expect(matches.call("New York, New York, United States", " new york ")).to be(true)
    end

    # Regression: a raw include? matched across component boundaries.
    it "does not match Kansas against Kansas City, Missouri" do
      expect(matches.call("Kansas City, Missouri, United States", "Kansas")).to be(false)
    end

    it "does not match Virginia against West Virginia" do
      expect(matches.call("West Virginia, United States", "Virginia")).to be(false)
    end

    it "does not match York against New York" do
      expect(matches.call("New York, New York, United States", "York")).to be(false)
    end

    it "returns false for a blank value" do
      expect(matches.call("Birmingham, Alabama, United States", "")).to be(false)
    end
  end

  describe "#score_location" do
    def location_score(city:, state:, locations:)
      p = create(:profile, city: city, state: state)
      scorer({locations: locations}, for_profile: p).send(:score_location)
    end

    it "scores 100 for a city match" do
      expect(location_score(city: "Birmingham", state: "Alabama",
        locations: ["Birmingham, Alabama, United States"])).to eq(100)
    end

    it "scores 75 for a state match without a city match" do
      expect(location_score(city: "Mobile", state: "Alabama",
        locations: ["Birmingham, Alabama, United States"])).to eq(75)
    end

    it "scores 25 for no match" do
      expect(location_score(city: "Mobile", state: "Alabama",
        locations: ["Denver, Colorado, United States"])).to eq(25)
    end

    # A Kansas resident should not get a state match for a Missouri trial.
    it "does not award a state match for Kansas City, Missouri" do
      expect(location_score(city: "Topeka", state: "Kansas",
        locations: ["Kansas City, Missouri, United States"])).to eq(25)
    end

    it "scores neutral when the trial has no locations" do
      expect(location_score(city: "Mobile", state: "Alabama", locations: [])).to eq(50)
    end
  end

  describe "condition matching recall" do
    subject(:matches) { ->(pc, tc) { scorer({}).send(:conditions_match?, pc, tc) } }

    it "splits a letter-digit run so Type2 tokenises as type and 2" do
      expect(matches.call("type 2 diabetes", "Type2 Diabetes Mellitus")).to be(true)
    end

    it "treats Roman numerals as their Arabic equivalents" do
      expect(matches.call("type 2 diabetes", "Type II Diabetes")).to be(true)
    end

    it "collapses an expansion to its abbreviation" do
      expect(matches.call("HIV/AIDS", "Human Immunodeficiency Virus")).to be(true)
    end

    it "treats carcinoma as cancer" do
      expect(matches.call("breast cancer", "Early-Stage Breast Carcinoma")).to be(true)
    end

    it "treats neoplasm as cancer" do
      expect(matches.call("breast cancer", "Breast Neoplasms")).to be(true)
    end

    # Every recall improvement is a loosening, and loosening is how the original
    # false-positive bug happened. These guarantees must survive it.
    it "still does not match breast cancer against lung cancer" do
      expect(matches.call("breast cancer", "lung cancer")).to be(false)
    end

    it "still does not match ms against symptoms" do
      expect(matches.call("ms", "symptoms")).to be(false)
    end

    it "does not match an unrelated co-condition" do
      expect(matches.call("breast cancer", "Brain Metastasis")).to be(false)
    end
  end

  describe "eligibility gates" do
    let(:neonatal) do
      {min_age: "0 Days", max_age: "28 Days", sex: "ALL",
       conditions: [], locations: [], phase: nil, study_type: nil}
    end

    def result_for(p, trial = neonatal) = described_class.new(p, trial).calculate_score

    # The defect this exists to fix. Measured before the change: a 40-year-old
    # scored 51 and "fair" on a trial recruiting infants aged 0 to 28 days.
    it "reports an adult as ineligible for a neonatal trial" do
      result = result_for(create(:profile, birth_year: 40.years.ago.year))

      expect(result[:eligible]).to be(false)
      expect(result[:match_level]).to eq(described_class::INELIGIBLE)
      expect(result[:total]).to eq(0)
    end

    it "names the failing gate" do
      result = result_for(create(:profile, birth_year: 40.years.ago.year))

      expect(result[:disqualifiers]).to include(:age)
    end

    it "still reports the full breakdown so the UI can explain why" do
      result = result_for(create(:profile, birth_year: 40.years.ago.year))

      expect(result[:breakdown].keys).to match_array(described_class::WEIGHTS.keys)
      expect(result[:breakdown][:age]).to eq(0)
    end

    it "reports an eligible profile as eligible" do
      result = result_for(create(:profile, birth_year: Time.current.year))

      expect(result[:eligible]).to be(true)
      expect(result[:disqualifiers]).to be_empty
      expect(result[:total]).to be > 0
    end

    # An incomplete profile must not be disqualified for what it has not filled
    # in. Only a definite mismatch is a gate.
    it "does not disqualify a profile with no age" do
      result = result_for(create(:profile, birth_year: nil))

      expect(result[:eligible]).to be(true)
    end

    it "does not disqualify a profile with no recorded sex" do
      trial = neonatal.merge(sex: "FEMALE", min_age: nil, max_age: nil)
      result = result_for(create(:profile, sex_assigned_at_birth: nil), trial)

      expect(result[:eligible]).to be(true)
    end

    it "disqualifies a definite sex mismatch" do
      trial = neonatal.merge(sex: "FEMALE", min_age: nil, max_age: nil)
      result = result_for(create(:profile, sex_assigned_at_birth: "male"), trial)

      expect(result[:disqualifiers]).to include(:sex)
    end

    # The gate treats any recorded sex as a definite answer, so every value the
    # profile form offers has to be one the registry can actually match. It
    # publishes ALL, FEMALE, or MALE and nothing else.
    #
    # "intersex" and "prefer not to say" were both offered and neither matched a
    # sex-restricted trial, so choosing them disqualified the user everywhere
    # while leaving the field blank did not. This fails if either comes back.
    it "offers only sexes that can match a sex-restricted trial" do
      Profile::SEX_ASSIGNED_AT_BIRTH_OPTIONS.each do |sex|
        eligible_somewhere = %w[FEMALE MALE].any? do |trial_sex|
          trial = neonatal.merge(sex: trial_sex, min_age: nil, max_age: nil)
          result_for(create(:profile, sex_assigned_at_birth: sex), trial)[:eligible]
        end

        expect(eligible_somewhere).to be(true),
          "#{sex.inspect} is offered but is disqualified from every sex-restricted " \
          "trial. Leave the field blank to decline instead of adding an option."
      end
    end

    it "an ineligible trial can never outrank an eligible one" do
      adult = create(:profile, birth_year: 40.years.ago.year)
      infant = create(:profile, birth_year: Time.current.year)

      expect(result_for(adult)[:total]).to be < result_for(infant)[:total]
    end
  end

  describe "recruiting status gate" do
    let(:base) do
      {min_age: nil, max_age: nil, sex: "ALL", conditions: [], locations: [], phase: nil, study_type: nil}
    end

    def result_with(status)
      described_class.new(create(:profile), base.merge(status: status)).calculate_score
    end

    %w[COMPLETED TERMINATED WITHDRAWN].each do |status|
      it "disqualifies a #{status} trial" do
        result = result_with(status)

        expect(result[:eligible]).to be(false)
        expect(result[:disqualifiers]).to include(:not_recruiting)
      end
    end

    # A trial that has not opened yet is a legitimate future option, and one
    # that is active but closed to new enrolment can reopen.
    %w[RECRUITING NOT_YET_RECRUITING ACTIVE_NOT_RECRUITING ENROLLING_BY_INVITATION].each do |status|
      it "does not disqualify a #{status} trial" do
        expect(result_with(status)[:eligible]).to be(true)
      end
    end

    it "does not disqualify an UNKNOWN status" do
      expect(result_with("UNKNOWN")[:eligible]).to be(true)
    end

    it "does not disqualify a missing status" do
      result = described_class.new(create(:profile), base).calculate_score

      expect(result[:eligible]).to be(true)
    end
  end

  describe "travel tolerance" do
    let(:distant) { {locations: ["Denver, Colorado, United States"]} }

    def location_score(miles)
      p = create(:profile, city: "Birmingham", state: "Alabama", willing_travel_miles: miles)
      described_class.new(p, distant).send(:score_location)
    end

    it "penalises a distant trial least for someone willing to travel far" do
      expect(location_score(Profile::HUNDRED_MILES)).to be > location_score(Profile::TEN_MILES)
    end

    it "scales monotonically with stated willingness" do
      scores = [Profile::TEN_MILES, Profile::TWENTYFIVE_MILES, Profile::FIFTY_MILES, Profile::HUNDRED_MILES]
        .map { |miles| location_score(miles) }

      expect(scores).to eq(scores.sort)
    end

    # An incomplete profile must score exactly as it did before this change.
    it "falls back to the previous flat score when travel tolerance is unset" do
      expect(location_score(nil)).to eq(described_class::DEFAULT_DISTANT_SCORE)
    end

    it "does not affect a city match" do
      p = create(:profile, city: "Denver", state: "Colorado", willing_travel_miles: Profile::TEN_MILES)

      expect(described_class.new(p, distant).send(:score_location)).to eq(100)
    end

    it "does not affect a state match" do
      p = create(:profile, city: "Boulder", state: "Colorado", willing_travel_miles: Profile::TEN_MILES)

      expect(described_class.new(p, distant).send(:score_location)).to eq(75)
    end
  end
end
