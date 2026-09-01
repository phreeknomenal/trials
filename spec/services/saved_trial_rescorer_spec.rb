require "rails_helper"

RSpec.describe SavedTrialRescorer do
  let(:user) { create(:user) }
  let(:study) { TrialFixtures.trial_fixture("NCT05444699") }

  before do
    user.profile.update!(first_name: "Dana", last_name: "Whitfield", zip_code: "35201",
      city: "Birmingham", state: "Alabama", birth_year: 1.year.ago.year)
  end

  def saved_trial(match_score: 99)
    create(:saved_trial, user: user, nct_id: "NCT05444699", match_score: match_score)
  end

  describe "#call" do
    before { allow(ClinicalTrialClient).to receive(:get_study).and_return(study) }

    it "overwrites a stale score" do
      trial = saved_trial(match_score: 99)

      described_class.new.call

      expect(trial.reload.match_score).not_to eq(99)
    end

    it "reports how many it rescored" do
      saved_trial

      expect(described_class.new.call.rescored).to eq(1)
    end

    it "writes nothing on a dry run" do
      trial = saved_trial(match_score: 99)

      result = described_class.new(dry_run: true).call

      expect(trial.reload.match_score).to eq(99)
      expect(result.rescored).to eq(1)
    end
  end

  describe "resilience" do
    it "records a failure rather than aborting when the API errors" do
      saved_trial
      allow(ClinicalTrialClient).to receive(:get_study).and_return({error: "not found"})

      result = described_class.new.call

      expect(result.failed).to eq(1)
      expect(result.errors.first).to include("NCT05444699")
    end

    it "records a failure rather than aborting when the lookup raises" do
      saved_trial
      allow(ClinicalTrialClient).to receive(:get_study).and_raise(Timeout::Error, "boom")

      result = described_class.new.call

      expect(result.failed).to eq(1)
      expect(result.rescored).to eq(0)
    end

    # One bad row must not stop the rest of the batch.
    it "continues past a failure to the remaining rows" do
      saved_trial
      other = create(:saved_trial, user: user, nct_id: "NCT07102836", match_score: 99)

      allow(ClinicalTrialClient).to receive(:get_study).with("NCT05444699").and_raise(Timeout::Error)
      allow(ClinicalTrialClient).to receive(:get_study).with("NCT07102836").and_return(study)

      result = described_class.new.call

      expect(result.failed).to eq(1)
      expect(result.rescored).to eq(1)
      expect(other.reload.match_score).not_to eq(99)
    end
  end
end
