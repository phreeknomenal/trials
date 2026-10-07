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

  describe ".record" do
    let(:user) { create(:user) }

    def record(answer, key: "q-0") = described_class.record(user: user, nct_id: "NCT00000001", question_key: key, answer: answer)

    it "stores a first answer with timestamps" do
      expect(record("yes")).to be(true)

      row = described_class.find_by!(user: user, nct_id: "NCT00000001", question_key: "q-0")
      expect(row.answer).to eq("yes")
      expect(row.created_at).to be_present
    end

    it "replaces an earlier answer rather than adding a second" do
      record("yes")

      expect { record("no") }.not_to change(described_class, :count)
      expect(described_class.for(user, "NCT00000001")).to eq("q-0" => "no")
    end

    # The race from review was a row landing between a find and a save: two
    # first answers in flight, both finding nothing. That gap cannot be opened
    # in a sequential test, and record has no gap to open, since it is one
    # statement. What can be pinned is the outcome: a row another request wrote,
    # inserted here behind ActiveRecord's back, is overwritten without raising.
    it "overwrites a row another request wrote, without raising" do
      now = Time.current
      described_class.insert_all([{user_id: user.id, nct_id: "NCT00000001", question_key: "q-0",
                                   answer: "yes", created_at: now, updated_at: now}])

      expect(record("no")).to be(true)
      expect(described_class.where(user: user, question_key: "q-0").pluck(:answer)).to eq(["no"])
    end

    it "writes nothing for an answer that is not yes, no, or not sure" do
      expect(record("maybe")).to be(false)
      expect(described_class.count).to eq(0)
    end

    it "leaves someone else's answer to the same question alone" do
      other = create(:prescreen_answer, nct_id: "NCT00000001", question_key: "q-0", answer: "yes")

      record("no")

      expect(other.reload.answer).to eq("yes")
    end
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
