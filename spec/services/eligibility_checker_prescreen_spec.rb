require "rails_helper"

RSpec.describe EligibilityChecker, "with prescreen answers" do
  let(:profile) { create(:user).profile }
  let(:trial) { {status: "RECRUITING", conditions: [], inclusion_criteria: "Diagnosis of asthma confirmed"} }
  let(:prescreen) { create(:study_prescreen, :completed) }

  # From the factory: q-0 "Have you been diagnosed with asthma?" is inclusion
  # and qualifies on yes. q-1 "Do you smoke?" is exclusion and qualifies on no.
  def checklist(answers, with_prescreen: prescreen)
    described_class.new(profile, trial, prescreen: with_prescreen, answers: answers).build_checklist
  end

  def item(answers, label) = checklist(answers).find { |i| i[:label] == label }

  it "meets an inclusion criterion answered yes" do
    expect(item({"q-0" => "yes"}, "Have you been diagnosed with asthma?")[:status]).to eq("met")
  end

  it "meets an exclusion criterion answered no" do
    expect(item({"q-1" => "no"}, "Do you smoke?")[:status]).to eq("met")
  end

  it "rules out on an exclusion answered yes, and says it rests on the answer" do
    smoking = item({"q-1" => "yes"}, "Do you smoke?")

    expect(smoking[:status]).to eq("not_met")
    expect(smoking[:explanation]).to eq("You answered yes. #{described_class::SELF_REPORTED_NOTE}")
  end

  it "leaves not sure with the study team" do
    expect(item({"q-0" => "unsure"}, "Have you been diagnosed with asthma?")[:status]).to eq("unknown")
  end

  it "carries the study's own wording behind the question" do
    expect(item({"q-1" => "no"}, "Do you smoke?")).to include(is_expandable: true, full_text: "Current smokers")
  end

  it "leaves unanswered questions out of the checklist" do
    labels = checklist({"q-0" => "yes"}).map { |i| i[:label] }

    expect(labels).to include("Have you been diagnosed with asthma?")
    expect(labels).not_to include("Do you smoke?")
  end

  it "drops the keyword skim once real questions exist" do
    expect(checklist({}).map { |i| i[:label] }).not_to include("Eligibility Criteria Highlights")
  end

  it "keeps the keyword skim for a study with no questions yet" do
    labels = checklist({}, with_prescreen: nil).map { |i| i[:label] }

    expect(labels).to include("Eligibility Criteria Highlights")
  end

  it "ignores answers to keys the current questions do not have" do
    expect(checklist({"stale-0" => "no"}).map { |i| i[:label] }).not_to include("stale-0")
  end
end
