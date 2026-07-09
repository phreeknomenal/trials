require "rails_helper"

RSpec.describe ReadableStudySummaryGenerator do
  let(:nct_id) { "NCT01234567" }
  let(:client) { instance_double(Anthropic::Client) }
  let(:messages) { double("messages") }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("ANTHROPIC_API_KEY").and_return("test-key")
    allow(Anthropic::Client).to receive(:new).and_return(client)
    allow(client).to receive(:messages).and_return(messages)
  end

  def text_block(text)
    double("text_block", type: :text, text: text)
  end

  def message(stop_reason:, blocks:)
    double("message", stop_reason: stop_reason, content: blocks)
  end

  describe "#call" do
    it "returns the rewritten plain-language text" do
      allow(ClinicalTrialClient).to receive(:get_study).with(nct_id).and_return(
        {summary: "Dense summary.", detailed_description: "Dense detail."}
      )
      allow(messages).to receive(:create).and_return(
        message(stop_reason: :end_turn, blocks: [text_block("Easy to read summary.")])
      )

      expect(described_class.new(nct_id).call).to eq("Easy to read summary.")
    end

    it "raises when the study lookup returns an error" do
      allow(ClinicalTrialClient).to receive(:get_study).with(nct_id).and_return(
        {error: "Study not found"}
      )

      expect { described_class.new(nct_id).call }
        .to raise_error(ReadableStudySummaryGenerator::GenerationError, "Study not found")
    end

    it "raises without calling Claude when the source text is blank" do
      allow(ClinicalTrialClient).to receive(:get_study).with(nct_id).and_return(
        {summary: nil, detailed_description: nil}
      )

      expect(Anthropic::Client).not_to receive(:new)
      expect { described_class.new(nct_id).call }
        .to raise_error(ReadableStudySummaryGenerator::GenerationError, /no source text/i)
    end

    it "raises when the model refuses" do
      allow(ClinicalTrialClient).to receive(:get_study).with(nct_id).and_return(
        {summary: "Dense summary."}
      )
      allow(messages).to receive(:create).and_return(
        message(stop_reason: :refusal, blocks: [])
      )

      expect { described_class.new(nct_id).call }
        .to raise_error(ReadableStudySummaryGenerator::GenerationError, /refused/i)
    end
  end
end
