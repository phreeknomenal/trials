require "rails_helper"

RSpec.describe TrialRecommendationService do
  let(:profile) { create(:user).profile }

  # Five outcomes used to be one empty array, so the dashboard said "nothing
  # matches you" when the registry had timed out. One is a fact about the
  # studies, the other a fact about our request.
  describe "#recommend" do
    it "says so when there is no profile at all" do
      result = described_class.new(nil).recommend

      expect(result.status).to eq(:no_profile)
      expect(result).to be_needs_profile
    end

    it "says so when the profile has no condition to match on" do
      result = described_class.new(profile).recommend

      expect(result.status).to eq(:no_condition)
      expect(result).to be_needs_profile
    end

    context "with a condition" do
      before { profile.conditions << Condition.create!(name: "Asthma") }

      def stub_client(response)
        allow(ClinicalTrialClient).to receive(:advanced_search).and_return(response)
      end

      # The client rescues its own failures into an :error key rather than
      # raising, so this was the one that looked exactly like an empty registry.
      it "reports unavailable when the client returns an error" do
        stub_client({studies: [], total_count: 0, error: "Search temporarily unavailable."})

        result = described_class.new(profile).recommend

        expect(result).to be_unavailable
        expect(result).not_to be_none_matched
      end

      it "reports unavailable when the request times out" do
        allow(ClinicalTrialClient).to receive(:advanced_search).and_raise(Timeout::Error)

        expect(described_class.new(profile).recommend).to be_unavailable
      end

      it "still rescues rather than raising, a slow third party not being fatal" do
        allow(ClinicalTrialClient).to receive(:advanced_search).and_raise(StandardError, "boom")

        expect { described_class.new(profile).recommend }.not_to raise_error
      end

      it "reports none matched when the registry answered with nothing" do
        stub_client({studies: [], total_count: 0})

        result = described_class.new(profile).recommend

        expect(result).to be_none_matched
        expect(result).not_to be_unavailable
      end

      it "reports none matched when studies came back but none scored high enough" do
        stub_client({studies: [{nct_id: "N1", title: "T", status: "RECRUITING",
                                min_age: "90 Years", conditions: ["Something else"]}], total_count: 1})

        expect(described_class.new(profile).recommend).to be_none_matched
      end

      it "returns the studies when there are any" do
        stub_client({studies: [{nct_id: "N1", title: "T", status: "RECRUITING",
                                conditions: ["Asthma"], study_type: "INTERVENTIONAL"}], total_count: 1})

        result = described_class.new(profile).recommend

        expect(result).to be_ok
        expect(result.any?).to be(true)
      end
    end
  end
end
