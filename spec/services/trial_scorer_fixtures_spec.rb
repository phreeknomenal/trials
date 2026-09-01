require "rails_helper"

# The harness that makes scoring changes measurable. Absolute score assertions
# would break on every legitimate weight change, which defeats the purpose, so
# these assert two things instead:
#
#   1. Schema guards -- the fixtures still parse into the shape the scorer needs.
#      A ClinicalTrials.gov schema change should fail loudly here rather than
#      quietly degrading scores in production.
#   2. Relational properties -- facts that must hold under any sane weighting,
#      such as an eligible profile outscoring an ineligible one on age.
RSpec.describe "TrialScorer against real trial fixtures" do
  def score_for(profile, trial)
    TrialScorer.new(profile, trial).calculate_score
  end

  def adult(**attrs) = create(:profile, birth_year: 40.years.ago.year, **attrs)

  def infant(**attrs) = create(:profile, birth_year: Time.current.year, **attrs)

  describe "schema guards" do
    it "has fixtures to test against" do
      expect(fixture_ids).not_to be_empty
    end

    fixture_ids = TrialFixtures.fixture_ids

    fixture_ids.each do |nct_id|
      context nct_id do
        let(:trial) { trial_fixture(nct_id) }

        it "carries the fields the scorer reads" do
          expect(trial.keys).to include(:nct_id, :conditions, :min_age, :max_age, :sex, :phase, :study_type, :locations, :status)
        end

        it "records its capture provenance" do
          meta = trial_fixture_metadata(nct_id)

          expect(meta[:captured_at]).to be_present
          expect(meta[:covers]).to be_present
        end

        it "produces a score between 0 and 100" do
          result = score_for(adult, trial)

          expect(result[:total]).to be_between(0, 100)
          expect(result[:match_level]).to be_present
        end

        it "returns a breakdown for every weighted criterion" do
          result = score_for(adult, trial)

          expect(result[:breakdown].keys).to match_array(TrialScorer::WEIGHTS.keys)
        end
      end
    end
  end

  describe "age handling on real paediatric payloads" do
    # Five of six fixtures use a non-year age unit. Reading the number and
    # ignoring the unit was a real bug; these are the payloads that catch it.
    it "parses every fixture's age limits below a human maximum" do
      TrialFixtures.fixture_ids.each do |nct_id|
        trial = trial_fixture(nct_id)
        scorer = TrialScorer.new(adult, trial)

        [trial[:min_age], trial[:max_age]].compact.each do |raw|
          parsed = scorer.send(:parse_age, raw)
          expect(parsed).to be < 130, "#{nct_id}: #{raw.inspect} parsed as #{parsed} years"
        end
      end
    end

    it "excludes an adult from a 0 to 28 day neonatal trial" do
      trial = trial_fixture("NCT07102836")

      expect(score_for(adult, trial)[:breakdown][:age]).to eq(0)
    end

    it "includes an infant in that same trial" do
      trial = trial_fixture("NCT07102836")

      expect(score_for(infant, trial)[:breakdown][:age]).to eq(100)
    end

    # Regression: "6 Months" read as 6 years excluded the toddlers this trial
    # is actually recruiting.
    it "includes a one-year-old in a 6 to 24 month trial" do
      toddler = create(:profile, birth_year: 1.year.ago.year)
      trial = trial_fixture("NCT05444699")

      expect(score_for(toddler, trial)[:breakdown][:age]).to eq(100)
    end

    it "ranks an eligible profile above an ineligible one on the same trial" do
      trial = trial_fixture("NCT05444699")
      toddler = create(:profile, birth_year: 1.year.ago.year)

      expect(score_for(toddler, trial)[:total]).to be > score_for(adult, trial)[:total]
    end
  end

  describe "locations" do
    it "scores neutral when a trial lists no locations" do
      trial = trial_fixture("NCT00524693")

      expect(trial[:locations]).to be_empty
      expect(score_for(adult, trial)[:breakdown][:location]).to eq(50)
    end

    it "does not raise on a trial with many locations" do
      trial = trial_fixture("NCT03774082")

      expect { score_for(adult, trial) }.not_to raise_error
    end
  end

  describe "recorded baseline" do
    # Not an assertion on the numbers, which should move as scoring improves.
    # This prints the current scores so a change shows up as a visible delta in
    # the spec output rather than being invisible.
    it "reports the current score for each fixture" do
      profile = adult(city: "Birmingham", state: "Alabama")

      rows = TrialFixtures.fixture_ids.map do |nct_id|
        result = score_for(profile, trial_fixture(nct_id))
        format("    %-14s total=%3d  %-10s %s", nct_id, result[:total], result[:match_level], result[:breakdown].inspect)
      end

      puts "\n  Baseline scores for a 40-year-old in Birmingham, Alabama:"
      puts rows

      expect(rows.length).to eq(TrialFixtures.fixture_ids.length)
    end
  end
end
