require "rails_helper"

RSpec.describe "The last two admin screens", type: :request do
  let(:staff) { create(:user, role: "admin") }

  before { sign_in staff }

  describe "users" do
    it "shows how far accounts get, which needs no row of the table" do
      create(:user).profile.update!(onboarded: true)
      create(:user).profile.update!(onboarded: false, onboarding_step: 3)

      get admin_users_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("How far accounts get")
      expect(response.body).to include("Onboarded")
      expect(response.body).to include("No profile")
    end

    # An account stuck at step 3 is a different thing from one that never
    # started, and "Incomplete" alone said neither.
    it "says which step an incomplete account stopped at" do
      create(:user).profile.update!(onboarded: false, onboarding_step: 3)

      get admin_users_path

      expect(response.body).to include("Incomplete")
      expect(response.body).to include("step 3")
    end

    # The screen has no edit control because it should not have one, not
    # because nobody built it.
    it "says the screen is read-only on purpose" do
      get admin_users_path

      expect(response.body).to include("No edit, suspend or impersonate from here")
      expect(response.body).to include("there is deliberately no link")
    end
  end

  describe "testimonials" do
    # The board puts the new form beside the list rather than on a page of its
    # own, so there is no separate new page to reach.
    it "carries the new form beside the list" do
      get admin_testimonials_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New testimonial")
      expect(response.body).to include("name=\"testimonial[quote]\"")
    end

    it "has no separate new page to link to" do
      expect { admin_testimonial_path(:new) }.not_to raise_error
      expect(Rails.application.routes.routes.map(&:name)).not_to include("new_admin_testimonial")
    end

    # A rejected create has to come back somewhere, and the page it came from
    # is the list.
    it "renders the list again when a create is rejected" do
      post admin_testimonials_path, params: {testimonial: {quote: "", author_name: ""}}

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Testimonials")
      expect(response.body).to match(/can.{0,6}t be blank/)
    end

    it "still creates one when the form is filled in" do
      expect {
        post admin_testimonials_path, params: {testimonial: {quote: "It helped.", author_name: "Denise R."}}
      }.to change(Testimonial, :count).by(1)

      expect(response).to redirect_to(admin_testimonials_path)
    end

    # A health testimonial names a real person's condition.
    it "says what may be published as a name" do
      get admin_testimonials_path

      expect(response.body).to include("Never a full name without written consent")
    end

    it "says how many are actually public" do
      create(:testimonial, published: true, placeholder: false)
      create(:testimonial, published: false, placeholder: true)

      get admin_testimonials_path

      expect(response.body).to include("showing on the landing page")
      expect(response.body).to include("held back and cannot be published")
    end
  end
end
