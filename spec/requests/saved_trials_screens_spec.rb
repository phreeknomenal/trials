require "rails_helper"

RSpec.describe "Saved studies screens", type: :request do
  let(:user) { create(:user) }

  before do
    user.profile.update!(onboarded: true, first_name: "Dana", last_name: "Whitfield", zip_code: "35201")
    sign_in user
  end

  def saved(status: "interested", **attrs)
    create(:saved_trial, user: user, status: status,
      nct_id: "NCT#{rand(10_000_000..99_999_999)}", **attrs)
  end

  describe "the index" do
    it "offers the statuses as a rail rather than hiding them in a select" do
      saved(status: "contacted")

      get saved_trials_path

      expect(response.body).to include("Filter by status")
      expect(response.body).to include("Contacted")
    end

    # Same rule the search sidebar follows: a facet counted after filtering
    # removes its own option and strands whoever clicked it.
    it "counts every status before the filter is applied" do
      saved(status: "interested")
      saved(status: "enrolled")

      get saved_trials_path(status: "enrolled")

      expect(response.body).to include("Interested")
      expect(response.body).to include("Enrolled")
    end

    it "keeps the status when searching from a filtered rail" do
      saved(status: "enrolled")

      get saved_trials_path(status: "enrolled")

      # Matched loosely: Rails puts id between name and value.
      expect(response.body).to match(/type="hidden"[^>]*name="status"[^>]*value="enrolled"/)
    end

    # There were two sets of checkboxes on this page answering the same
    # question, and the pair belonging to "Select All" had no endpoint and no
    # JavaScript behind it.
    it "has one set of checkboxes, read by both actions" do
      saved

      get saved_trials_path

      expect(response.body.scan('data-selection-target="checkbox"').count).to eq(1)
      expect(response.body).not_to include('form="compare-trials-form"')
    end

    it "points the bulk action at an endpoint that exists" do
      saved

      get saved_trials_path

      expect(response.body).to include(bulk_update_saved_trials_path)
    end

    it "says plainly when nothing matches a filter" do
      get saved_trials_path(status: "enrolled")

      expect(response.body).to include("Nothing here matches")
    end

    it "says something different when nothing is saved at all" do
      get saved_trials_path

      expect(response.body).to include("Nothing saved yet")
    end

    # There is no distance in the data. locations_detailed carries a near_you
    # boolean from a string match on city and state.
    it "shows no distance, because there is none" do
      saved

      get saved_trials_path

      expect(response.body).not_to match(/\d+\s*mi\b/)
    end
  end

  describe "the study" do
    it "leads with the pipeline rather than hiding status in a form" do
      record = saved(status: "applying")

      get saved_trial_path(record)

      expect(response.body).to include("Where you are with it")
      expect(response.body).to include("Move to contacted")
    end

    # Four of the seven statuses are a sequence. The other three are somebody
    # else's decision or the study ending, so putting them on the same line
    # would imply you progress into them.
    it "keeps the terminal statuses off the pipeline but reachable" do
      record = saved(status: "interested")

      get saved_trial_path(record)

      expect(response.body).to include("Rejected, completed and not eligible live in that list too")
    end

    it "says a terminal study is outside the pipeline" do
      record = saved(status: "rejected")

      get saved_trial_path(record)

      expect(response.body).to include("outside the pipeline")
    end

    it "offers no next step from a terminal status" do
      record = saved(status: "completed")

      get saved_trial_path(record)

      expect(response.body).not_to match(/Move to (interested|applying|contacted|enrolled)/)
    end

    # The score was worked out against the profile as it stood when the study
    # was saved, and a profile that changed since would score it differently.
    it "says which profile the score was worked out against" do
      record = saved(match_score: 88)

      get saved_trial_path(record)

      expect(response.body).to include("profile you had when you saved this")
    end
  end

  describe "the edit form" do
    it "offers notes and tags" do
      record = saved

      get edit_saved_trial_path(record)

      expect(response.body).to include("Notes", "Tags")
    end

    # Status moved to the pipeline, where it takes one press instead of a form
    # and a Save.
    it "no longer offers status" do
      record = saved

      get edit_saved_trial_path(record)

      expect(response.body).not_to include("saved_trial[status]")
    end

    # PR #146 stopped update permitting it. A disabled field for a number
    # nobody edits is furniture.
    it "no longer shows the match score" do
      record = saved(match_score: 72)

      get edit_saved_trial_path(record)

      expect(response.body).not_to include("saved_trial[match_score]")
    end

    it "still saves notes and tags" do
      record = saved

      patch saved_trial_path(record), params: {saved_trial: {tags: "travel ok, UAB"}}

      expect(record.reload.tags_array).to eq(["travel ok", "UAB"])
    end

    # The pipeline's own button PATCHes the same action, so status has to stay
    # permitted even though the form no longer offers it.
    it "still accepts a status change from the pipeline" do
      record = saved(status: "interested")

      patch saved_trial_path(record), params: {saved_trial: {status: "contacted"}}

      expect(record.reload.status).to eq("contacted")
    end
  end
end
