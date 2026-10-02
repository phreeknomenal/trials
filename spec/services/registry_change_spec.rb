require "rails_helper"

RSpec.describe RegistryChange do
  def saved(trial_status: "RECRUITING", registry_status: "RECRUITING",
    seen: Date.new(2026, 9, 1), latest: Date.new(2026, 9, 1), checked: Time.current, why_stopped: nil)
    build(:saved_trial,
      trial_status: trial_status,
      registry_status: registry_status,
      seen_last_update: seen,
      registry_last_update: latest,
      registry_checked_at: checked,
      registry_why_stopped: why_stopped)
  end

  describe ".for" do
    it "is nil before the first check, whatever the columns hold" do
      expect(described_class.for(saved(registry_status: "COMPLETED", checked: nil))).to be_nil
    end

    it "is nil when nothing moved" do
      expect(described_class.for(saved)).to be_nil
    end

    it "calls recruiting to completed stopped" do
      expect(described_class.for(saved(registry_status: "COMPLETED")).kind).to eq(:stopped)
    end

    # Not in TrialStatus::CLOSED, and still the end of the road for a new
    # participant. The case the badge would miss if it read CLOSED.
    it "calls recruiting to active-not-recruiting stopped" do
      expect(described_class.for(saved(registry_status: "ACTIVE_NOT_RECRUITING")).kind).to eq(:stopped)
    end

    # Not yet recruiting is in ACCEPTING, since a site will take a name for it.
    it "calls not-yet-recruiting to withdrawn stopped" do
      change = described_class.for(saved(trial_status: "NOT_YET_RECRUITING", registry_status: "WITHDRAWN"))
      expect(change.kind).to eq(:stopped)
    end

    it "calls suspended to recruiting started" do
      expect(described_class.for(saved(trial_status: "SUSPENDED")).kind).to eq(:started)
    end

    it "calls completed to terminated a status change" do
      change = described_class.for(saved(trial_status: "COMPLETED", registry_status: "TERMINATED"))
      expect(change.kind).to eq(:status)
    end

    it "ignores the registry's own spelling differences" do
      expect(described_class.for(saved(trial_status: "Recruiting", registry_status: "RECRUITING"))).to be_nil
    end

    it "reports no status change when the saved status was never recorded" do
      expect(described_class.for(saved(trial_status: nil, registry_status: "COMPLETED"))).to be_nil
    end

    it "calls a newer update date updated" do
      expect(described_class.for(saved(latest: Date.new(2026, 9, 20))).kind).to eq(:updated)
    end

    it "puts a status change ahead of the update that came with it" do
      change = described_class.for(saved(registry_status: "COMPLETED", latest: Date.new(2026, 9, 20)))
      expect(change.kind).to eq(:stopped)
    end

    it "does not call an unknown baseline date an update" do
      expect(described_class.for(saved(seen: nil, latest: Date.new(2026, 9, 20)))).to be_nil
    end
  end

  describe "#explanation" do
    it "names both statuses in words" do
      change = described_class.for(saved(registry_status: "ACTIVE_NOT_RECRUITING"))
      expect(change.explanation).to eq(
        "It was listed as recruiting when you last looked. " \
        "The registry now lists it as active not recruiting."
      )
    end

    # The show page builds the change, then acknowledges it, then renders it.
    # Acknowledging rewrites trial_status on the same record.
    it "still describes the change after it has been acknowledged" do
      record = create(:saved_trial, trial_status: "RECRUITING", registry_status: "COMPLETED",
        registry_checked_at: Time.current)
      change = described_class.for(record)

      record.acknowledge_registry!

      expect(change.explanation).to include("listed as recruiting")
      expect(change.explanation).to include("now lists it as completed")
    end

    it "dates an update and says the registry does not record what changed" do
      change = described_class.for(saved(latest: Date.new(2026, 9, 20)))
      expect(change.explanation).to include("September 20, 2026")
      expect(change.explanation).to include("does not say what changed")
    end
  end

  describe "#why_stopped" do
    it "gives the team's reason when the study stopped" do
      change = described_class.for(saved(registry_status: "TERMINATED", why_stopped: "Sponsor decision"))
      expect(change.why_stopped).to eq("Sponsor decision")
    end

    it "drops a leftover reason when the study started again" do
      change = described_class.for(saved(trial_status: "SUSPENDED", why_stopped: "Paused for review"))
      expect(change.why_stopped).to be_nil
    end
  end
end
