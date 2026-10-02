require "rails_helper"

RSpec.describe StudyPrescreen do
  let(:study) { {inclusion_criteria: "Diagnosis of asthma", exclusion_criteria: "Current smokers"} }

  describe ".digest_for" do
    it "changes when either side of the criteria changes" do
      digest = described_class.digest_for(study)

      expect(described_class.digest_for(study.merge(inclusion_criteria: "Diagnosis of COPD"))).not_to eq(digest)
      expect(described_class.digest_for(study.merge(exclusion_criteria: "Pregnancy"))).not_to eq(digest)
    end

    # Without the separator, moving a line from one side to the other would hash
    # the same, and the questions' yes and no would be backwards.
    it "tells inclusion text from the same text on the exclusion side" do
      expect(described_class.digest_for({inclusion_criteria: "A", exclusion_criteria: nil}))
        .not_to eq(described_class.digest_for({inclusion_criteria: nil, exclusion_criteria: "A"}))
    end
  end

  describe "#current_for?" do
    it "is true for completed questions written from the study's criteria today" do
      prescreen = build(:study_prescreen, :completed, criteria_digest: described_class.digest_for(study))
      expect(prescreen.current_for?(study)).to be(true)
    end

    it "is false once the study edits its criteria" do
      prescreen = build(:study_prescreen, :completed, criteria_digest: described_class.digest_for(study))
      expect(prescreen.current_for?(study.merge(exclusion_criteria: "Pregnancy"))).to be(false)
    end

    it "is false while pending" do
      prescreen = build(:study_prescreen, criteria_digest: described_class.digest_for(study))
      expect(prescreen.current_for?(study)).to be(false)
    end
  end

  describe "#question_list" do
    it "reads the stored questions back as Question values" do
      question = create(:study_prescreen, :completed).reload.question_list.last

      expect(question).to have_attributes(key: "q-1", side: "exclusion", qualifying_answer: "no")
    end
  end

  describe StudyPrescreen::Question do
    let(:exclusion) { create(:study_prescreen, :completed).question_list.last }

    it "qualifies an exclusion question on no" do
      expect(exclusion.qualifies?("no")).to be(true)
      expect(exclusion.disqualifies?("yes")).to be(true)
    end

    it "neither qualifies nor disqualifies on not sure" do
      expect(exclusion.qualifies?("unsure")).to be(false)
      expect(exclusion.disqualifies?("unsure")).to be(false)
    end
  end
end
