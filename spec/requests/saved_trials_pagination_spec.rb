require "rails_helper"

RSpec.describe "Saved trials pagination", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  def create_trials(count)
    count.times { |n| create(:saved_trial, user: user, trial_title: "Trial number #{n}") }
  end

  context "with a single page" do
    it "renders no pagination controls" do
      create_trials(3)

      get saved_trials_path

      expect(response.body).not_to include("Next")
      expect(response.body).not_to match(/Page \d+ of/)
    end
  end

  context "with more than one page" do
    before { create_trials(25) }

    # The view previously rendered "Page 1 of 2" with no links at all, so a
    # member with more than one page had no way to reach the second.
    it "renders a next link" do
      get saved_trials_path

      expect(response.body).to include("Next")
    end

    it "shows the position and total" do
      get saved_trials_path

      expect(response.body).to match(/Page\s+1\s+of\s+2/)
      expect(response.body).to include("25 trials")
    end

    it "does not render a previous link on the first page" do
      get saved_trials_path

      expect(response.body).not_to include("Previous")
    end

    it "serves page 2 with different records" do
      get saved_trials_path
      first_page = response.body

      get saved_trials_path(page: 2)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to eq(first_page)
      expect(response.body).to include("Previous")
    end
  end

  context "page size" do
    before { create_trials(25) }

    # `items:` was silently ignored by Pagy 43, so this paginated at the gem
    # default regardless of what the controller passed.
    it "honours per_page" do
      get saved_trials_path(per_page: 5)

      expect(response.body).to match(/Page\s+1\s+of\s+5/)
    end

    it "falls back to the default for a non-numeric per_page" do
      get saved_trials_path(per_page: "abc")

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/Page\s+1\s+of\s+2/)
    end

    it "does not raise on per_page=0" do
      expect { get saved_trials_path(per_page: 0) }.not_to raise_error
      expect(response).to have_http_status(:ok)
    end

    it "clamps an absurd per_page" do
      get saved_trials_path(per_page: 100000)

      expect(response).to have_http_status(:ok)
    end
  end

  it "keeps other query params when paginating" do
    create_trials(25)

    get saved_trials_path(status: SavedTrial::INTERESTED)

    expect(response.body).to include("status=#{SavedTrial::INTERESTED}")
  end
end
