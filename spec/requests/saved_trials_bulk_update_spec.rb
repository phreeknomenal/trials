require "rails_helper"

# The page has offered a "Mark as" control for a multiple selection since it was
# written. There was no endpoint behind it, no JavaScript wiring it up, and the
# container holding it starts hidden with nothing to unhide it. It had never
# done anything at all.
#
# Fifth instance of that shape in this project, after the sort dropdown that
# sent a value the service did not branch on, the photo control whose Stimulus
# controller was never written, the footer's nine unclickable links, and the
# hero's distance select.
RSpec.describe "Bulk updating saved studies", type: :request do
  let(:user) { create(:user) }
  let(:other) { create(:user) }

  before do
    user.profile.update!(onboarded: true, first_name: "Dana", last_name: "Whitfield", zip_code: "35201")
    sign_in user
  end

  def saved(owner: user, status: "interested", nct: nil)
    create(:saved_trial, user: owner, status: status, nct_id: nct || "NCT#{rand(10_000_000..99_999_999)}")
  end

  it "moves every selected study" do
    a, b = saved, saved

    patch bulk_update_saved_trials_path, params: {status: "contacted", saved_trial_ids: [a.id, b.id]}

    expect([a.reload.status, b.reload.status]).to eq(%w[contacted contacted])
  end

  it "leaves the ones that were not selected alone" do
    a = saved
    b = saved

    patch bulk_update_saved_trials_path, params: {status: "enrolled", saved_trial_ids: [a.id]}

    expect(b.reload.status).to eq("interested")
  end

  it "says how many moved" do
    a, b = saved, saved

    patch bulk_update_saved_trials_path, params: {status: "applying", saved_trial_ids: [a.id, b.id]}

    follow_redirect!
    expect(response.body).to include("2 studies moved to applying")
  end

  # Scoped through the policy rather than found by id, so a forged id belonging
  # to somebody else updates nothing rather than raising or, worse, working.
  it "cannot touch another person's saved study" do
    theirs = saved(owner: other)

    patch bulk_update_saved_trials_path, params: {status: "enrolled", saved_trial_ids: [theirs.id]}

    expect(theirs.reload.status).to eq("interested")
  end

  it "refuses a status a study cannot be in" do
    a = saved

    patch bulk_update_saved_trials_path, params: {status: "wandering", saved_trial_ids: [a.id]}

    expect(a.reload.status).to eq("interested")
    follow_redirect!
    expect(response.body).to include("not a status")
  end

  it "does nothing when nothing was selected" do
    a = saved

    patch bulk_update_saved_trials_path, params: {status: "enrolled", saved_trial_ids: []}

    expect(a.reload.status).to eq("interested")
  end

  it "is closed to a signed-out visitor" do
    sign_out user
    a = saved

    patch bulk_update_saved_trials_path, params: {status: "enrolled", saved_trial_ids: [a.id]}

    expect(a.reload.status).to eq("interested")
    expect(response).to redirect_to(new_user_session_path)
  end
end
