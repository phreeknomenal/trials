require "rails_helper"

RSpec.describe "Answering prescreen questions", type: :request do
  let(:user) { create(:user) }
  let!(:prescreen) { create(:study_prescreen, :completed) }
  let(:nct_id) { prescreen.nct_id }

  def answer(key: "q-0", value: "yes", id: nct_id)
    post prescreen_answers_path(id), params: {question_key: key, answer: value}
  end

  it "sends a signed-out visitor to sign in and stores nothing" do
    expect { answer }.not_to change(PrescreenAnswer, :count)
    expect(response).to redirect_to(new_user_session_path)
  end

  describe "signed in" do
    before { sign_in user }

    it "stores the answer and sends the person back to the questions" do
      answer

      expect(PrescreenAnswer.for(user, nct_id)).to eq("q-0" => "yes")
      expect(response).to redirect_to(search_path(nct_id))
    end

    it "changes an earlier answer instead of adding a second" do
      answer(value: "yes")

      expect { answer(value: "unsure") }.not_to change(PrescreenAnswer, :count)
      expect(PrescreenAnswer.for(user, nct_id)).to eq("q-0" => "unsure")
    end

    it "refuses a key the study's questions do not have" do
      expect { answer(key: "made-up") }.not_to change(PrescreenAnswer, :count)
      expect(flash[:alert]).to include("no longer on this study")
    end

    it "refuses an answer that is not yes, no, or not sure" do
      expect { answer(value: "maybe") }.not_to change(PrescreenAnswer, :count)
      expect(flash[:alert]).to include("yes, no, or not sure")
    end

    it "refuses a study whose questions are not written yet" do
      pending_one = create(:study_prescreen)

      expect { answer(id: pending_one.nct_id) }.not_to change(PrescreenAnswer, :count)
    end
  end
end
