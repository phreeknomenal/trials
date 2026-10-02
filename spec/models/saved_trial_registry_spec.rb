require "rails_helper"

RSpec.describe SavedTrial, "registry checks" do
  let(:saved_trial) { create(:saved_trial, trial_status: "RECRUITING") }
  let(:study) do
    {status: "COMPLETED", last_update: "2026-09-20", why_stopped: "Enrollment target met"}
  end

  describe ".registry_stale" do
    it "includes rows never checked and rows checked over a day ago, not fresh ones" do
      never = create(:saved_trial)
      old = create(:saved_trial, registry_checked_at: 25.hours.ago)
      create(:saved_trial, registry_checked_at: 1.hour.ago)

      expect(described_class.registry_stale).to contain_exactly(never, old)
    end
  end

  describe "#record_registry!" do
    it "stores what the registry says" do
      saved_trial.record_registry!(study)

      expect(saved_trial.reload).to have_attributes(
        registry_status: "COMPLETED",
        registry_last_update: Date.new(2026, 9, 20),
        registry_why_stopped: "Enrollment target met"
      )
      expect(saved_trial.registry_checked_at).to be_within(1.second).of(Time.current)
    end

    it "makes the first registry date the baseline, so a first check badges nothing by date" do
      saved_trial.record_registry!(study.merge(status: "RECRUITING"))

      expect(saved_trial.reload.seen_last_update).to eq(Date.new(2026, 9, 20))
      expect(RegistryChange.for(saved_trial)).to be_nil
    end

    it "leaves an existing baseline alone" do
      saved_trial.update_columns(seen_last_update: Date.new(2026, 9, 1))
      saved_trial.record_registry!(study)

      expect(saved_trial.reload.seen_last_update).to eq(Date.new(2026, 9, 1))
    end

    # The dashboard reads updated_at as the person's own activity.
    it "does not touch updated_at" do
      saved_trial.update_columns(updated_at: 10.days.ago)

      expect { saved_trial.record_registry!(study) }.not_to(change { saved_trial.reload.updated_at })
    end
  end

  describe "#acknowledge_registry!" do
    it "makes the latest registry values the baseline and clears the change" do
      saved_trial.update_columns(seen_last_update: Date.new(2026, 9, 1))
      saved_trial.record_registry!(study)
      expect(RegistryChange.for(saved_trial)).to be_present

      saved_trial.acknowledge_registry!

      expect(saved_trial.reload).to have_attributes(
        trial_status: "COMPLETED",
        seen_last_update: Date.new(2026, 9, 20)
      )
      expect(RegistryChange.for(saved_trial)).to be_nil
    end

    it "does nothing before the first check" do
      expect { saved_trial.acknowledge_registry! }.not_to(change { saved_trial.reload.attributes })
    end

    it "does not touch updated_at" do
      saved_trial.record_registry!(study)
      saved_trial.update_columns(updated_at: 10.days.ago)

      expect { saved_trial.acknowledge_registry! }.not_to(change { saved_trial.reload.updated_at })
    end
  end
end
