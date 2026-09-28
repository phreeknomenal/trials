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
      expect(response.body).to include("Nothing stuck or failed")
    end
  end

  context "with a failed summary" do
    it "lists it with its error message" do
      create(:readable_study_summary, :failed, nct_id: "NCT11111111", error_message: "Claude refused the request")

      get admin_operations_path

      expect(response.body).to include("NCT11111111", "Claude refused the request")
      expect(response.body).not_to include("Nothing stuck or failed")
    end

    it "falls back when no error message was recorded" do
      create(:readable_study_summary, :failed, error_message: nil)

      get admin_operations_path

      expect(response.body).to include("No error message recorded")
    end
  end

  context "with a stale pending summary" do
    it "lists it under stale" do
      stale_summary("NCT22222222")

      get admin_operations_path

      expect(response.body).to include("Stale", "NCT22222222")
    end

    # A stuck record must not also appear as healthy in-progress work.
    it "excludes it from in progress" do
      stale_summary("NCT22222222")
      create(:readable_study_summary, nct_id: "NCT33333333")

      get admin_operations_path

      # Scoped to the sections rather than counted across the page: the requeue
      # button puts the id in its form action too, so a raw count measures the
      # markup rather than which list the record landed in.
      page = Nokogiri::HTML(response.body)
      section_for = ->(heading) {
        page.css("section").find { |s| s.css("h2").text.include?(heading) }.to_s
      }

      expect(section_for.call("Stale")).to include("NCT22222222")
      expect(section_for.call("Stale")).not_to include("NCT33333333")
      expect(section_for.call("Pending, running normally")).to include("NCT33333333")
      expect(section_for.call("Pending, running normally")).not_to include("NCT22222222")
    end
  end

  # The board offers Retry and Requeue. Both are the existing summaries endpoint,
  # which already resets a failed record and re-enqueues a stale one, so this is
  # wiring rather than a new capability. Exercised rather than assumed: five
  # controls in this project have shipped with nothing behind them.
  describe "the retry controls" do
    it "offers a retry on a failed row that posts to the real endpoint" do
      create(:readable_study_summary, :failed, nct_id: "NCT11111111")

      get admin_operations_path

      expect(response.body).to include("Retry")
      expect(response.body).to include(readable_summary_path("NCT11111111"))
    end

    it "puts a failed summary back in the queue when retried" do
      summary = create(:readable_study_summary, :failed, nct_id: "NCT11111111",
        error_message: "Something broke")

      expect {
        post readable_summary_path("NCT11111111")
      }.to have_enqueued_job(GenerateReadableStudySummaryJob).with("NCT11111111")

      expect(summary.reload).to be_pending
      expect(summary.error_message).to be_nil
    end

    it "re-enqueues a stale one when requeued" do
      stale_summary("NCT22222222")

      expect {
        post readable_summary_path("NCT22222222")
      }.to have_enqueued_job(GenerateReadableStudySummaryJob).with("NCT22222222")
    end

    # A retry is a paid Claude call on the same allowance a patient spends.
    it "says what a retry costs" do
      create(:readable_study_summary, :failed)

      get admin_operations_path

      expect(response.body).to include("counts against the same hourly and daily")
    end
  end

  describe "the counts" do
    it "leads with four, so the queue reads before the rows do" do
      create(:readable_study_summary, :completed)
      create(:readable_study_summary, :failed)

      get admin_operations_path

      expect(response.body).to include("Completed", "Pending, healthy", "Stale over", "Failed")
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
