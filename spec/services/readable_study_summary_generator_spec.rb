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

  # A truncated summary reads as complete: it just stops mid-sentence. Caching
  # one means a patient reads half an explanation and cannot tell.
  describe "when the model runs out of room" do
    before do
      allow(ClinicalTrialClient).to receive(:get_study).with(nct_id).and_return(
        {summary: "Dense protocol prose.", detailed_description: "A great deal more of it."}
      )
      allow(messages).to receive(:create).and_return(
        message(stop_reason: :max_tokens, blocks: [text_block("This study is looking at whether")])
      )
    end

    it "raises rather than returning the half it got" do
      expect { described_class.new(nct_id).call }
        .to raise_error(described_class::GenerationError)
    end

    it "says the summary was cut off" do
      expect { described_class.new(nct_id).call }
        .to raise_error(described_class::GenerationError, /cut off/)
    end

    it "does not return the truncated text" do
      result = begin
        described_class.new(nct_id).call
      rescue described_class::GenerationError
        nil
      end

      expect(result).to be_nil
    end
  end

  describe "the token ceiling" do
    it "leaves room for a long rewrite" do
      expect(described_class::MAX_TOKENS).to be >= 4096
    end

    it "is what the request asks for" do
      allow(ClinicalTrialClient).to receive(:get_study).with(nct_id).and_return(
        {summary: "Prose.", detailed_description: nil}
      )
      allow(messages).to receive(:create).and_return(
        message(stop_reason: :end_turn, blocks: [text_block("Readable.")])
      )

      described_class.new(nct_id).call

      expect(messages).to have_received(:create)
        .with(hash_including(max_tokens: described_class::MAX_TOKENS))
    end
  end
end
