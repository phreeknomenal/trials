require "rails_helper"

RSpec.describe GenerateStudyPrescreenJob, type: :job do
  let(:nct_id) { "NCT01234567" }
  let(:generator) { instance_double(StudyPrescreenGenerator) }
  let(:questions) do
    [{"key" => "abc-0", "text" => "Do you smoke?", "source" => "Current smoker",
      "side" => "exclusion", "qualifying_answer" => "no"}]
  end

  before do
    allow(StudyPrescreenGenerator).to receive(:new).with(nct_id).and_return(generator)
    allow(Turbo::StreamsChannel).to receive(:broadcast_refresh_to)
  end

  it "stores the questions and the digest they came from" do
    allow(generator).to receive(:call).and_return(
      StudyPrescreenGenerator::Result.new(questions: questions, criteria_digest: "abc123")
    )

    described_class.perform_now(nct_id)

    record = StudyPrescreen.find_by!(nct_id: nct_id)
    expect(record).to have_attributes(status: "completed", criteria_digest: "abc123", error_message: nil)
    expect(record.question_list.first.qualifying_answer).to eq("no")
  end

  it "marks the record failed with a message a patient can read" do
    allow(generator).to receive(:call).and_raise(StudyPrescreenGenerator::GenerationError, "internal detail")

    described_class.perform_now(nct_id)

    expect(StudyPrescreen.find_by!(nct_id: nct_id)).to have_attributes(
      status: "failed", error_message: described_class::GENERIC_ERROR_MESSAGE
    )
  end

  it "does not pay twice for a study already done" do
    create(:study_prescreen, :completed, nct_id: nct_id)
    allow(generator).to receive(:call)

    described_class.perform_now(nct_id)

    expect(generator).not_to have_received(:call)
  end

  it "refreshes open study pages whether it succeeded or failed" do
    allow(generator).to receive(:call).and_raise(StandardError)

    described_class.perform_now(nct_id)

    expect(Turbo::StreamsChannel).to have_received(:broadcast_refresh_to).with("study_prescreen_#{nct_id}")
  end
end
