require "rails_helper"

RSpec.describe "Admin operations", type: :request do
  let(:admin) { create(:user, role: "admin") }

  before { sign_in admin }

  def stale_summary(nct_id)
    create(:readable_study_summary, nct_id: nct_id).tap do |s|
      s.update_column(:updated_at, (ReadableStudySummary::STALE_AFTER + 1.minute).ago)
    end
  end

  context "with nothing wrong" do
    it "shows an all-clear state" do
      create(:readable_study_summary, :completed)

      get admin_operations_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No failed or stuck summaries")
    end
  end

  context "with a failed summary" do
    it "lists it with its error message" do
      create(:readable_study_summary, :failed, nct_id: "NCT11111111", error_message: "Claude refused the request")

      get admin_operations_path

      expect(response.body).to include("NCT11111111", "Claude refused the request")
      expect(response.body).not_to include("No failed or stuck summaries")
    end

    it "falls back when no error message was recorded" do
      create(:readable_study_summary, :failed, error_message: nil)

      get admin_operations_path

      expect(response.body).to include("No error message recorded")
    end
  end

  context "with a stale pending summary" do
    it "lists it under stuck" do
      stale_summary("NCT22222222")

      get admin_operations_path

      expect(response.body).to include("Stuck", "NCT22222222")
    end

    # A stuck record must not also appear as healthy in-progress work.
    it "excludes it from in progress" do
      stale_summary("NCT22222222")
      create(:readable_study_summary, nct_id: "NCT33333333")

      get admin_operations_path

      stuck_index = response.body.index("NCT22222222")
      fresh_index = response.body.index("NCT33333333")

      expect(stuck_index).to be < fresh_index
      expect(response.body.scan("NCT22222222").length).to eq(1)
    end
  end

  context "as a member" do
    it "is denied" do
      sign_in create(:user, role: "member")

      get admin_operations_path

      expect(response).to redirect_to(root_path)
    end
  end
end
