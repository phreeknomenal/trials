require "rails_helper"

# Two navigations exist at phone width: the slide-over panel for a visitor, and
# the tab bar for someone signed in. The board's rule is that the tab bar
# *replaces* the top nav, so the failure worth guarding is both appearing at
# once, or neither.
RSpec.describe "Mobile navigation", type: :request do
  let(:user) { create(:user) }

  before { user.profile.update!(onboarded: true, first_name: "Dana", last_name: "Whitfield", zip_code: "35201") }

  describe "signed in" do
    before do
      sign_in user
      get my_trials_root_path
    end

    it "serves the tab bar" do
      expect(response.body).to include(%(aria-label="Main"))
      expect(response.body).to include("My trials", "Find", "Saved", "Profile")
    end

    it "does not also offer the slide-over panel" do
      expect(response.body).not_to include(%(data-action="mobile-menu#toggle"))
    end

    it "keeps the dark mode toggle reachable, which the panel used to carry" do
      expect(response.body).to match(/dark-mode|theme/i)
    end

    # The bar is fixed, so without a spacer the last of the page sits under it.
    it "reserves the bar's height in the flow" do
      expect(response.body).to include("h-20 lg:hidden")
    end
  end

  describe "signed out" do
    before { get root_path }

    it "keeps the slide-over panel" do
      expect(response.body).to include(%(data-action="mobile-menu#toggle"))
      expect(response.body).to include("mobile-menu-panel")
    end

    it "serves no tab bar" do
      expect(response.body).not_to include("My trials")
    end
  end

  # Sign out and account settings lived in the panel. Removing the panel for
  # signed-in mobile would have stranded both if the footer did not carry them,
  # which it has since PR #147.
  describe "what the panel used to be the only route to" do
    before do
      sign_in user
      get my_trials_root_path
    end

    it "still offers sign out" do
      expect(response.body).to include(destroy_user_session_path)
    end

    it "still offers account settings" do
      expect(response.body).to include(edit_user_registration_path)
    end
  end
end
