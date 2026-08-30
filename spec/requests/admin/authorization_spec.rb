require "rails_helper"

RSpec.describe "Admin access", type: :request do
  describe "GET /admin" do
    context "as an unauthenticated visitor" do
      it "redirects to sign in" do
        get admin_root_path

        expect(response).to redirect_to(new_user_session_path)
      end

      it "does not render the admin page" do
        get admin_root_path

        expect(response.body).not_to include("Admin")
      end
    end

    context "as a member" do
      let(:user) { create(:user, role: "member") }

      before { sign_in user }

      # Before the rescue_from added alongside this namespace, a failed
      # authorize raised Pundit::NotAuthorizedError and surfaced as a 500.
      it "redirects to root rather than raising" do
        expect { get admin_root_path }.not_to raise_error
        expect(response).to redirect_to(root_path)
      end

      it "sets an alert" do
        get admin_root_path

        expect(flash[:alert]).to be_present
      end

      it "does not render admin content" do
        get admin_root_path
        follow_redirect!

        expect(response.body).not_to include("Signed in as")
      end
    end

    User::STAFF_ROLES.each do |role|
      context "as #{role}" do
        let(:user) { create(:user, role: role) }

        before { sign_in user }

        it "renders the admin dashboard" do
          get admin_root_path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Signed in as")
        end

        it "uses the admin layout rather than the public one" do
          get admin_root_path

          expect(response.body).to include("Admin — Trials")
          expect(response.body).to include("Back to site")
        end
      end
    end
  end
end
