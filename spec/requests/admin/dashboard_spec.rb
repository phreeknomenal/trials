require "rails_helper"

RSpec.describe "Admin dashboard", type: :request do
  let(:admin) { create(:user, role: "admin") }

  before { sign_in admin }

  # Production has one user and zero saved trials, so a near-empty database is
  # the normal state rather than an edge case.
  context "with an almost empty database" do
    it "renders without raising" do
      expect { get admin_root_path }.not_to raise_error
      expect(response).to have_http_status(:ok)
    end

    it "does not divide by zero when no profiles are onboarded" do
      Profile.destroy_all

      get admin_root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("no profiles yet")
    end

    it "shows empty messages rather than blank charts" do
      get admin_root_path

      expect(response.body).to include("No saved trials yet")
    end
  end

  context "with data" do
    before do
      create(:testimonial, :placeholder)
      create(:testimonial)
      create(:readable_study_summary, :completed)
      create(:readable_study_summary, :failed)
    end

    it "counts users" do
      get admin_root_path

      expect(response.body).to include("Users")
    end

    it "separates seeded placeholders from real testimonials" do
      get admin_root_path

      expect(response.body).to include("Seeded placeholders")
      expect(response.body).to include("replace before public launch")
    end

    it "surfaces failed summaries and links to operations" do
      get admin_root_path

      expect(response.body).to include("Failed")
      expect(response.body).to include("View details on the operations page")
    end

    it "does not link to operations when nothing is wrong" do
      ReadableStudySummary.failed.destroy_all

      get admin_root_path

      expect(response.body).not_to include("View details on the operations page")
    end
  end

  it "denies members" do
    sign_in create(:user, role: "member")

    get admin_root_path

    expect(response).to redirect_to(root_path)
  end
end
