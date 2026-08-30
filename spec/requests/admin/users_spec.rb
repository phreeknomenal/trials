require "rails_helper"

RSpec.describe "Admin users", type: :request do
  let(:admin) { create(:user, role: "admin") }

  before { sign_in admin }

  it "lists users with their roles" do
    create(:user, email: "member@test.dev", role: "member")

    get admin_users_path

    expect(response.body).to include("member@test.dev", "member")
  end

  it "shows profile completion state" do
    user = create(:user)
    user.profile.update!(onboarded: true, first_name: "Dana", last_name: "Whitfield", zip_code: "35201")

    get admin_users_path

    expect(response.body).to include("Onboarded")
  end

  it "paginates beyond the page size" do
    30.times { create(:user) }

    get admin_users_path

    expect(response.body).to include("Page 1 of")
    expect(response.body).to include("Next")
  end

  it "serves the second page" do
    30.times { create(:user) }

    get admin_users_path(page: 2)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Previous")
  end

  # Without includes(:profile) this is one query per row.
  it "avoids an N+1 on profiles" do
    5.times { create(:user) }

    queries = 0
    counter = ->(*, payload) { queries += 1 unless payload[:name] == "SCHEMA" }

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      get admin_users_path
    end

    expect(queries).to be < 20
  end

  it "denies members" do
    sign_in create(:user, role: "member")

    get admin_users_path

    expect(response).to redirect_to(root_path)
  end
end
