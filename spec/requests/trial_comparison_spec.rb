require "rails_helper"

RSpec.describe "Comparing saved studies", type: :request do
  let(:user) { create(:user) }

  before do
    user.profile.update!(onboarded: true, first_name: "Dana", last_name: "Whitfield", zip_code: "35201")
    sign_in user
    allow(ClinicalTrialClient).to receive(:get_study).and_return({error: "unavailable"})
  end

  def saved_study(**attrs)
    create(:saved_trial, {user: user, trial_title: "A study", phase: "PHASE3",
                          sponsor: "Novo Nordisk", trial_status: "RECRUITING"}.merge(attrs))
  end

  def compare(*trials)
    get my_trials_trial_comparison_path(ids: trials.map(&:id).join(","))
  end

  it "marks the rows where the studies differ" do
    compare(saved_study, saved_study(sponsor: "Eli Lilly"))

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("DIFFERS")
    expect(response.body).to include('data-differs="true"')
  end

  # The one job the page has. It used to lay eleven rows out at equal weight.
  it "offers to hide the rows where they agree" do
    compare(saved_study, saved_study(sponsor: "Eli Lilly"))

    expect(response.body).to include("Only show rows that differ")
    expect(response.body).to include('data-controller="comparison-filter"')
  end

  it "says so rather than offering a filter when nothing differs" do
    compare(saved_study, saved_study)

    expect(response.body).to include("are the same on every row compared")
    expect(response.body).not_to include("Only show rows that differ")
  end

  it "names the studies and offers a way into each" do
    a = saved_study(trial_title: "Semaglutide in adults")
    b = saved_study(trial_title: "Tirzepatide versus standard care")

    compare(a, b)

    expect(response.body).to include("Semaglutide in adults")
    expect(response.body).to include("Tirzepatide versus standard care")
    expect(response.body.scan("Open this one").count).to eq(2)
  end

  it "spells how many are being compared" do
    compare(saved_study, saved_study)

    expect(response.body).to include("Two studies, side by side")
  end

  # The registry is stubbed unreachable above, so every column falls back to the
  # score stored when it was saved. Said rather than hidden.
  it "says which column it could not rescore" do
    compare(saved_study(match_score: 80), saved_study(match_score: 60))

    expect(response.body).to include("Could not reach the registry for this one")
  end

  it "still refuses fewer than two" do
    compare(saved_study)

    expect(response).to redirect_to(my_trials_saved_trials_path)
  end
end
