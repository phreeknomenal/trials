require "rails_helper"

# This search path had never executed successfully before the Postgres
# migration: ILIKE is not implemented by SQLite, and `notes` is an ActionText
# rich text rather than a column on saved_trials. Both are fixed, so these are
# the first tests the feature has ever had.
RSpec.describe "GET /saved_trials", type: :request do
  let(:user) { create(:user) }

  def search(term)
    get saved_trials_path(search: term)
  end

  before { sign_in user }

  context "with no search param" do
    it "returns all saved trials for the current user" do
      create(:saved_trial, user: user, trial_title: "Alpha study")
      create(:saved_trial, user: user, trial_title: "Beta study")

      get saved_trials_path

      expect(response.body).to include("Alpha study", "Beta study")
    end
  end

  context "with a search term matching trial_title" do
    before do
      create(:saved_trial, user: user, trial_title: "Cardiology outcomes")
      create(:saved_trial, user: user, trial_title: "Dermatology review")
    end

    it "returns the matching trial" do
      search("Cardiology")

      expect(response.body).to include("Cardiology outcomes")
    end

    it "excludes non-matching trials" do
      search("Cardiology")

      expect(response.body).not_to include("Dermatology review")
    end
  end

  context "with a search term matching notes" do
    it "returns the trial whose rich-text notes match" do
      match = create(:saved_trial, user: user, trial_title: "Notes carrier")
      match.notes = "spoke with the coordinator on Tuesday"
      match.save!
      create(:saved_trial, user: user, trial_title: "Unrelated trial")

      search("coordinator")

      expect(response.body).to include("Notes carrier")
      expect(response.body).not_to include("Unrelated trial")
    end
  end

  context "with a search term differing only in case" do
    it "still matches, confirming ILIKE case-insensitivity" do
      create(:saved_trial, user: user, trial_title: "Oncology trial")

      search("ONCOLOGY")

      expect(response.body).to include("Oncology trial")
    end
  end

  context "with a term containing a % wildcard" do
    it "treats % as a literal character rather than a wildcard" do
      create(:saved_trial, user: user, trial_title: "Reached 100% enrollment")
      # Decoy must contain "100" so an unescaped % (matching any suffix) would
      # wrongly include it. A decoy without "100" would pass either way.
      create(:saved_trial, user: user, trial_title: "Reached 1000 participants")

      search("100%")

      expect(response.body).to include("Reached 100% enrollment")
      expect(response.body).not_to include("Reached 1000 participants")
    end
  end

  context "with a term containing an _ wildcard" do
    it "treats _ as a literal character" do
      create(:saved_trial, user: user, trial_title: "Phase_II cohort")
      create(:saved_trial, user: user, trial_title: "PhaseXII cohort")

      search("Phase_II")

      expect(response.body).to include("Phase_II cohort")
      expect(response.body).not_to include("PhaseXII cohort")
    end
  end

  context "when the trial belongs to another user" do
    it "is excluded by the policy scope regardless of search match" do
      create(:saved_trial, user: create(:user), trial_title: "Someone elses trial")

      search("Someone")

      expect(response.body).not_to include("Someone elses trial")
    end
  end
end
