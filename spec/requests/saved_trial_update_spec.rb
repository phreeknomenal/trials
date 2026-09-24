require "rails_helper"

RSpec.describe "Updating a saved trial", type: :request do
  let(:user) { create(:user) }
  let(:saved) do
    create(:saved_trial, user: user, match_score: 42, trial_title: "The real title",
      sponsor: "The real sponsor", phase: "PHASE2")
  end

  before { sign_in user }

  it "saves what the form actually offers" do
    patch saved_trial_path(saved), params: {saved_trial: {notes: "Called the site", tags: "travel ok", status: SavedTrial::CONTACTED}}

    # notes is has_rich_text, so it reads back as an ActionText::RichText.
    expect(saved.reload.notes.to_plain_text).to eq("Called the site")
    expect(saved).to have_attributes(tags: "travel ok", status: SavedTrial::CONTACTED)
  end

  # The form showed the match score read-only and never offered the registry
  # fields at all, but update permitted all sixteen. The dashboard counts saved
  # trials at match_score >= 80, which makes that the number worth forging.
  describe "fields the form does not offer" do
    it "refuses a hand-made match score" do
      patch saved_trial_path(saved), params: {saved_trial: {notes: "x", match_score: 100}}

      expect(saved.reload.match_score).to eq(42)
    end

    it "refuses a rewritten registry snapshot" do
      patch saved_trial_path(saved), params: {
        saved_trial: {notes: "x", trial_title: "Something else", sponsor: "Someone else", phase: "PHASE3"}
      }

      expect(saved.reload).to have_attributes(
        trial_title: "The real title", sponsor: "The real sponsor", phase: "PHASE2"
      )
    end

    it "saves the parts it does offer even when refused fields are sent alongside" do
      patch saved_trial_path(saved), params: {saved_trial: {notes: "kept", match_score: 100}}

      expect(saved.reload.notes.to_plain_text).to eq("kept")
    end
  end

  # Creating still snapshots the registry's own fields, so create keeps the wide
  # list and only update is narrow.
  it "still lets a new saved trial carry its snapshot" do
    post saved_trials_path, params: {
      saved_trial: {nct_id: "NCT99", trial_title: "A study", sponsor: "A sponsor", match_score: 77}
    }, as: :json

    created = user.saved_trials.find_by(nct_id: "NCT99")
    expect(created).to have_attributes(trial_title: "A study", sponsor: "A sponsor", match_score: 77)
  end
end
