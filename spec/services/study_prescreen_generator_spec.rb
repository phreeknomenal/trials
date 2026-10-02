require "rails_helper"

RSpec.describe StudyPrescreenGenerator do
  let(:nct_id) { "NCT01234567" }
  let(:client) { instance_double(Anthropic::Client) }
  let(:beta) { double("beta") }
  let(:messages) { double("messages") }
  let(:study) do
    {
      inclusion_criteria: "* Diagnosis of moderate asthma for at least 1 year\n* Age 18 to 65",
      exclusion_criteria: "* Current smoker\n* Pregnant or breastfeeding\n* eGFR below 60"
    }
  end

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("ANTHROPIC_API_KEY").and_return("test-key")
    allow(Anthropic::Client).to receive(:new).and_return(client)
    allow(client).to receive(:beta).and_return(beta)
    allow(beta).to receive(:messages).and_return(messages)
    allow(ClinicalTrialClient).to receive(:get_study).with(nct_id).and_return(study)
  end

  def question(text, source, side, qualifying_answer)
    {"text" => text, "source" => source, "side" => side, "qualifying_answer" => qualifying_answer}
  end

  def respond_with(questions, stop_reason: :end_turn)
    body = JSON.generate({"questions" => questions})
    allow(messages).to receive(:create).and_return(
      double("message", stop_reason: stop_reason, content: [double("text_block", type: :text, text: body)])
    )
  end

  def generate = described_class.new(nct_id).call

  describe "#call" do
    it "returns the questions with keys from the criteria digest, and the digest" do
      respond_with([
        question("Have you had moderate asthma for at least a year?",
          "Diagnosis of moderate asthma for at least 1 year", "inclusion", "yes"),
        question("Do you currently smoke?", "Current smoker", "exclusion", "no")
      ])

      result = generate
      digest = StudyPrescreen.digest_for(study)

      expect(result.criteria_digest).to eq(digest)
      expect(result.questions.map { |q| q["key"] }).to eq(["#{digest.first(10)}-0", "#{digest.first(10)}-1"])
      expect(result.questions.last).to include("side" => "exclusion", "qualifying_answer" => "no")
    end

    it "asks for structured output on the current Opus with refusal fallbacks" do
      respond_with([])

      generate

      expect(messages).to have_received(:create).with(hash_including(
        model: "claude-opus-5-5",
        fallbacks: :default,
        betas: [:"server-side-fallback-2026-07-01"],
        output_config: hash_including(format_: hash_including(type: :json_schema))
      ))
    end

    it "sends both lists, labelled" do
      respond_with([])

      generate

      expect(messages).to have_received(:create) do |params|
        content = params[:messages].first[:content]
        expect(content).to include("Inclusion criteria:\n* Diagnosis of moderate asthma")
        expect(content).to include("Exclusion criteria:\n* Current smoker")
      end
    end

    # The page shows source as the study's own words.
    it "drops a question whose quote is not in the study's text" do
      respond_with([
        question("Do you have severe asthma?", "Diagnosis of severe asthma", "inclusion", "yes"),
        question("Do you currently smoke?", "Current smoker", "exclusion", "no")
      ])

      expect(generate.questions.map { |q| q["source"] }).to eq(["Current smoker"])
    end

    # A criterion filed under the wrong list has its yes and no backwards.
    it "drops a question quoted from the other list than the side it claims" do
      respond_with([question("Do you currently smoke?", "Current smoker", "inclusion", "yes")])

      expect(generate.questions).to be_empty
    end

    it "matches a quote across case and whitespace differences" do
      respond_with([question("Are you pregnant or breastfeeding?", "pregnant  or\nbreastfeeding", "exclusion", "no")])

      expect(generate.questions.size).to eq(1)
    end

    it "drops a question with an empty quote, which every text contains" do
      respond_with([question("Anything?", "  ", "inclusion", "yes")])

      expect(generate.questions).to be_empty
    end

    it "keeps at most MAX_QUESTIONS" do
      respond_with(Array.new(StudyPrescreen::MAX_QUESTIONS + 3) { question("Do you smoke?", "Current smoker", "exclusion", "no") })

      expect(generate.questions.size).to eq(StudyPrescreen::MAX_QUESTIONS)
    end

    it "handles a study with only one list" do
      allow(ClinicalTrialClient).to receive(:get_study).with(nct_id).and_return(
        {inclusion_criteria: "Diagnosis of asthma", exclusion_criteria: nil}
      )
      respond_with([question("Do you have asthma?", "Diagnosis of asthma", "inclusion", "yes")])

      expect(generate.questions.size).to eq(1)
      expect(messages).to have_received(:create) do |params|
        expect(params[:messages].first[:content]).to include("Exclusion criteria:\n(none listed)")
      end
    end

    it "raises without calling Claude when the study lists no criteria" do
      allow(ClinicalTrialClient).to receive(:get_study).with(nct_id).and_return({inclusion_criteria: nil, exclusion_criteria: ""})
      allow(messages).to receive(:create)

      expect { generate }.to raise_error(described_class::GenerationError, /no eligibility criteria/)
      expect(messages).not_to have_received(:create)
    end

    it "raises when the study lookup fails" do
      allow(ClinicalTrialClient).to receive(:get_study).with(nct_id).and_return({error: "Study not found"})

      expect { generate }.to raise_error(described_class::GenerationError, "Study not found")
    end

    it "raises on a refusal" do
      respond_with([], stop_reason: :refusal)

      expect { generate }.to raise_error(described_class::GenerationError, /declined/)
    end

    it "raises on truncation rather than keeping half a list" do
      respond_with([], stop_reason: :max_tokens)

      expect { generate }.to raise_error(described_class::GenerationError, /longer than we allow/)
    end

    it "raises on output it cannot parse" do
      allow(messages).to receive(:create).and_return(
        double("message", stop_reason: :end_turn, content: [double("text_block", type: :text, text: "not json")])
      )

      expect { generate }.to raise_error(described_class::GenerationError, /could not read/)
    end
  end
end
