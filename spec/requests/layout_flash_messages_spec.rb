require "rails_helper"

# Three layouts render a flash and only two of them used the shared component.
#
# `unauthenticated` still carried the Rails scaffold default:
#
#   <p class="notice"><%= notice %></p>
#   <p class="alert"><%= alert %></p>
#
# `.notice` and `.alert` are scaffold class names this app never styled, so a
# signed-out visitor got bare unstyled text outside the page container. Those
# two helpers also only read :notice and :alert, so the four other keys the
# component understands were dropped without a trace.
#
# `onboarding` rendered no flash at all, and ensure_profile_completed redirects
# an incomplete profile there from any HTML request, so a flash set before that
# redirect had nowhere to land.
RSpec.describe "Flash messages in every layout", type: :request do
  describe "the auth layout, where a signed-out redirect lands" do
    # Devise sets flash[:alert] from devise.failure.unauthenticated and bounces
    # to sign-in, which is the most common way a visitor sees a flash at all.
    # Since PR 8 that lands on the auth layout rather than the unauthenticated
    # one, and the message renders inside the form column.
    before do
      get my_trials_root_path
      follow_redirect!
    end

    it "renders the message through the shared component" do
      expect(response.body).to include("main-flash-messages")
    end

    it "no longer renders the unstyled scaffold paragraphs" do
      expect(response.body).not_to include('<p class="alert">')
      expect(response.body).not_to include('<p class="notice">')
    end

    it "still shows the message text" do
      expect(response.body).to include(
        "You need to sign in or sign up before continuing."
      )
    end
  end

  describe "the onboarding layout" do
    let(:user) { create(:user, :onboarding) }

    # Signing in sets flash[:notice], and ensure_profile_completed then
    # redirects an incomplete profile into the wizard. The notice is only ever
    # rendered by the layout it lands on.
    before do
      post user_session_path, params: {
        user: {email: user.email, password: "password123"}
      }
      follow_redirect!
      follow_redirect! while response.redirect?
    end

    it "lands on the wizard" do
      expect(request.path).to start_with("/onboarding/")
    end

    it "renders the sign-in notice rather than dropping it" do
      expect(response.body).to include("main-flash-messages")
    end
  end

  # The unauthenticated layout no longer has a reachable signed-out flash path,
  # Devise having moved to its own layout, so this asserts on the template
  # itself. Weaker than a request, and the point is only that the scaffold
  # paragraphs have not come back.
  describe "the unauthenticated layout" do
    let(:template) { Rails.root.join("app/views/layouts/unauthenticated.html.erb").read }

    it "renders flashes through the shared component" do
      expect(template).to include("Shared::FlashMessagesComponent")
    end

    it "carries no scaffold flash paragraphs" do
      expect(template).not_to include(%(<p class="alert">))
      expect(template).not_to include(%(<p class="notice">))
    end
  end
end
