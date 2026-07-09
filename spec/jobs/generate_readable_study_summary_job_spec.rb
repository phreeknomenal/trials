require "rails_helper"

RSpec.describe GenerateReadableStudySummaryJob, type: :job do
  let(:nct_id) { "NCT01234567" }
  let(:generator) { instance_double(ReadableStudySummaryGenerator) }

  before do
    allow(ReadableStudySummaryGenerator).to receive(:new).with(nct_id).and_return(generator)
    allow(Turbo::StreamsChannel).to receive(:broadcast_update_to)
  end

  def rate_limit_error
    Anthropic::Errors::RateLimitError.new(
      url: URI("https://api.anthropic.com"),
      status: 429,
      headers: {},
      body: nil,
      request: nil,
      response: nil,
      message: "rate limited"
    )
  end

  describe "#perform" do
    it "stores the generated summary and marks the record completed" do
      allow(generator).to receive(:call).and_return("A readable summary.")

      described_class.new.perform(nct_id)

      record = ReadableStudySummary.find_by(nct_id: nct_id)
      expect(record.completed?).to be(true)
      expect(record.content).to eq("A readable summary.")
      expect(record.generated_at).to be_present
    end

    it "broadcasts an update to the wrapper target on success" do
      allow(generator).to receive(:call).and_return("A readable summary.")

      described_class.new.perform(nct_id)

      expect(Turbo::StreamsChannel).to have_received(:broadcast_update_to).with(
        "readable_study_summary_#{nct_id}",
        hash_including(target: "readable-study-summary-content-#{nct_id}")
      )
    end

    it "short-circuits when the record is already completed" do
      create(:readable_study_summary, :completed, nct_id: nct_id)

      described_class.new.perform(nct_id)

      expect(ReadableStudySummaryGenerator).not_to have_received(:new)
    end

    it "marks the record failed and logs on a generic error" do
      allow(generator).to receive(:call).and_raise(StandardError, "boom")
      allow(Rails.logger).to receive(:error)

      described_class.new.perform(nct_id)

      record = ReadableStudySummary.find_by(nct_id: nct_id)
      expect(record.failed?).to be(true)
      expect(record.error_message).to eq(described_class::GENERIC_ERROR_MESSAGE)
      expect(record.error_message).not_to include("boom")
      expect(Rails.logger).to have_received(:error).with(/boom/)
    end

    it "broadcasts an update on failure" do
      allow(generator).to receive(:call).and_raise(StandardError, "boom")

      described_class.new.perform(nct_id)

      expect(Turbo::StreamsChannel).to have_received(:broadcast_update_to).with(
        "readable_study_summary_#{nct_id}",
        hash_including(target: "readable-study-summary-content-#{nct_id}")
      )
    end

    it "propagates a rate-limit error without marking the record failed" do
      allow(generator).to receive(:call).and_raise(rate_limit_error)

      expect { described_class.new.perform(nct_id) }
        .to raise_error(Anthropic::Errors::RateLimitError)

      record = ReadableStudySummary.find_by(nct_id: nct_id)
      expect(record.failed?).to be(false)
      expect(Turbo::StreamsChannel).to have_received(:broadcast_update_to).with(
        "readable_study_summary_#{nct_id}",
        hash_including(target: "readable-study-summary-content-#{nct_id}")
      )
    end
  end
end
