require "rails_helper"

RSpec.describe EligibilityChecker do
  # The checklist renders this as one flowing line, so pipe separators arrived
  # on the page as debris from whatever produced them.
  it "separates the parsed criteria highlights with semicolons, not pipes" do
    profile = create(:user).profile
    trial = {inclusion_criteria: "Confirmed diagnosis required. Adequate liver and renal function. ECOG performance status 0-1."}

    highlights = described_class.new(profile, trial).build_checklist
      .find { |item| item[:label] == "Eligibility Criteria Highlights" }

    expect(highlights[:explanation]).not_to include("|")
    expect(highlights[:explanation]).to include("; ")
  end
end
