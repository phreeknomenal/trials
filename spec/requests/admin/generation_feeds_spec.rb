require "rails_helper"

RSpec.describe "Prescreen questions on the admin pages", type: :request do
  let(:admin) { create(:user, role: "admin") }

  before { sign_in admin }

  def feed_html(id) = Nokogiri::HTML(response.body).at_css("##{id}").to_s

  describe "operations" do
    it "lists a failed prescreen with a retry that writes questions, not a summary" do
      create(:study_prescreen, nct_id: "NCT44444444", status: "failed", error_message: "We couldn't write questions.")

      get admin_operations_path

      prescreens = feed_html("study_prescreen-feed")
      expect(prescreens).to include("NCT44444444", "We couldn't write questions.")
      expect(prescreens).to include(study_prescreen_path("NCT44444444"))
      expect(prescreens).to include("lists no eligibility criteria will fail again")
      expect(feed_html("readable_study_summary-feed")).not_to include("NCT44444444")
    end

    # The all-clear is for the whole page. A healthy summary queue must not
    # announce "nothing stuck" while prescreens are failing.
    it "withholds the all-clear when only prescreens are failing" do
      create(:readable_study_summary, :completed)
      create(:study_prescreen, status: "failed")

      get admin_operations_path

      expect(response.body).not_to include("Nothing stuck or failed")
    end

    it "counts both queues in the all-clear" do
      create(:readable_study_summary, :completed)
      create(:study_prescreen, :completed)

      get admin_operations_path

      expect(response.body).to include("1 summary and 1 question set cached")
    end
  end

  describe "dashboard" do
    it "reports the prescreen queue beside the summary queue" do
      create(:study_prescreen, status: "failed")

      get admin_root_path

      prescreens = Nokogiri::HTML(response.body).css("section").find { |s| s.at_css("h2")&.text&.include?("Prescreen questions") }
      expect(prescreens).to be_present
      expect(prescreens.text.squish).to include("Failed 1")
      expect(prescreens.to_s).to include(admin_operations_path(anchor: "study_prescreen-feed"))
    end
  end
end
