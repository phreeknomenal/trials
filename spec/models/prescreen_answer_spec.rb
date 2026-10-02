require "rails_helper"

RSpec.describe PrescreenAnswer do
  it "allows one answer per person, study, and question" do
    answer = create(:prescreen_answer)
    duplicate = build(:prescreen_answer, user: answer.user, nct_id: answer.nct_id, question_key: answer.question_key)

    expect(duplicate).not_to be_valid
  end

  it "accepts only yes, no, and not sure" do
    expect(build(:prescreen_answer, answer: "maybe")).not_to be_valid
  end

  it "goes with the account" do
    answer = create(:prescreen_answer)

    expect { answer.user.destroy }.to change(described_class, :count).by(-1)
  end

  describe ".for" do
    it "maps question keys to one person's answers on one study" do
      user = create(:user)
      create(:prescreen_answer, user: user, nct_id: "NCT00000001", question_key: "q-0", answer: "yes")
      create(:prescreen_answer, user: user, nct_id: "NCT00000002", question_key: "q-0", answer: "no")
      create(:prescreen_answer, nct_id: "NCT00000001", question_key: "q-1", answer: "no")

      expect(described_class.for(user, "NCT00000001")).to eq("q-0" => "yes")
    end

    it "is empty for a signed-out visitor" do
      expect(described_class.for(nil, "NCT00000001")).to eq({})
    end
  end
end
