require "rails_helper"

RSpec.describe "Saved studies that changed on the registry", type: :request do
  let(:user) { create(:user) }
  let!(:saved) do
    create(:saved_trial, user: user, trial_title: "Inhaler study", trial_status: "RECRUITING",
      registry_status: "TERMINATED", registry_why_stopped: "Sponsor decision",
      registry_last_update: Date.new(2026, 9, 20), seen_last_update: Date.new(2026, 9, 1),
      registry_checked_at: 1.hour.ago)
  end

  before { sign_in user }

  def badge = Nokogiri::HTML(response.body).at_css("#saved-trial-#{saved.id} [data-registry-change]")

  it "badges the card on the saved list" do
    get saved_trials_path

    expect(badge&.text&.squish).to eq("No longer recruiting")
  end

  it "badges nothing on a study that has not moved" do
    saved.update_columns(registry_status: "RECRUITING", registry_last_update: Date.new(2026, 9, 1))

    get saved_trials_path

    expect(badge).to be_nil
  end

  it "says what changed and why on the saved study" do
    get saved_trial_path(saved)

    notice = Nokogiri::HTML(response.body).at_css("#registry-change").text.squish
    expect(notice).to include("No longer recruiting")
    expect(notice).to include("It was listed as recruiting when you last looked.")
    expect(notice).to include("The registry now lists it as terminated.")
    expect(notice).to include("The study team's reason: Sponsor decision")
  end

  it "clears the badge once the study has been opened" do
    get saved_trial_path(saved)
    get saved_trials_path

    expect(badge).to be_nil
  end

  it "shows no notice on the next open" do
    get saved_trial_path(saved)
    get saved_trial_path(saved)

    expect(Nokogiri::HTML(response.body).at_css("#registry-change")).to be_nil
  end

  # Opening a study is not acting on it. The dashboard's awaiting-reply panel
  # reads updated_at as the person's own last move.
  it "does not count opening the study as activity" do
    saved.update_columns(updated_at: 10.days.ago)

    expect { get saved_trial_path(saved) }.not_to(change { saved.reload.updated_at })
  end
end
