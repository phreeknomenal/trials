require "rails_helper"

RSpec.describe RefreshSavedTrialsJob, type: :job do
  let(:user) { create(:user) }

  def study(status: "COMPLETED")
    {status: status, last_update: "2026-09-20", why_stopped: nil}
  end

  it "records the registry's answer on each stale saved study" do
    saved = create(:saved_trial, user: user, trial_status: "RECRUITING")
    allow(ClinicalTrialClient).to receive(:get_study).with(saved.nct_id).and_return(study)

    described_class.perform_now(user.id)

    expect(saved.reload.registry_status).to eq("COMPLETED")
    expect(RegistryChange.for(saved).kind).to eq(:stopped)
  end

  it "skips studies checked within the day" do
    create(:saved_trial, user: user, registry_checked_at: 1.hour.ago)
    allow(ClinicalTrialClient).to receive(:get_study)

    described_class.perform_now(user.id)

    expect(ClinicalTrialClient).not_to have_received(:get_study)
  end

  it "leaves other people's studies alone" do
    create(:saved_trial)
    allow(ClinicalTrialClient).to receive(:get_study)

    described_class.perform_now(user.id)

    expect(ClinicalTrialClient).not_to have_received(:get_study)
  end

  it "checks at most PER_RUN studies, never-checked first, then the oldest" do
    stub_const("#{described_class}::PER_RUN", 2)
    old = create(:saved_trial, user: user, registry_checked_at: 3.days.ago)
    never = create(:saved_trial, user: user)
    create(:saved_trial, user: user, registry_checked_at: 2.days.ago)
    allow(ClinicalTrialClient).to receive(:get_study).and_return(study)

    described_class.perform_now(user.id)

    expect(ClinicalTrialClient).to have_received(:get_study).twice
    expect(ClinicalTrialClient).to have_received(:get_study).with(never.nct_id)
    expect(ClinicalTrialClient).to have_received(:get_study).with(old.nct_id)
  end

  # Stays stale, so the next visit tries again.
  it "leaves a study unchecked when the registry errors, and carries on" do
    failing = create(:saved_trial, user: user)
    working = create(:saved_trial, user: user)
    allow(ClinicalTrialClient).to receive(:get_study).with(failing.nct_id).and_return({error: "Study not found"})
    allow(ClinicalTrialClient).to receive(:get_study).with(working.nct_id).and_return(study)

    described_class.perform_now(user.id)

    expect(failing.reload.registry_checked_at).to be_nil
    expect(working.reload.registry_checked_at).to be_present
  end

  it "carries on past an exception on one study" do
    failing = create(:saved_trial, user: user)
    working = create(:saved_trial, user: user)
    allow(ClinicalTrialClient).to receive(:get_study).with(failing.nct_id).and_raise(Timeout::Error)
    allow(ClinicalTrialClient).to receive(:get_study).with(working.nct_id).and_return(study)

    expect { described_class.perform_now(user.id) }.not_to raise_error
    expect(working.reload.registry_checked_at).to be_present
  end
end
