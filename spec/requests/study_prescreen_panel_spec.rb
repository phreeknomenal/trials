require "rails_helper"

RSpec.describe "The prescreen panel on a study", type: :request do
  let(:user) { create(:user) }
  let(:nct_id) { "NCT01234567" }
  let(:study) do
    {nct_id: nct_id, title: "An asthma study", summary: "A study.", conditions: ["Asthma"],
     status: "RECRUITING", phase: "PHASE2", study_type: "INTERVENTIONAL", min_age: "18 Years",
     max_age: "65 Years", sex: "ALL", inclusion_criteria: "Diagnosis of asthma",
     exclusion_criteria: "Current smokers", interventions: [], locations: [],
     central_contacts: [], overall_officials: []}
  end

  before { allow(ClinicalTrialClient).to receive(:get_study).with(nct_id).and_return(study) }

  def page = Nokogiri::HTML(response.body)

  def panel = page.at_css("#prescreen")&.text&.squish

  def current_prescreen(**attrs)
    create(:study_prescreen, :completed, nct_id: nct_id, criteria_digest: StudyPrescreen.digest_for(study), **attrs)
  end

  it "morphs on refresh and keeps the scroll position" do
    get search_path(nct_id)

    expect(page.at_css('meta[name="turbo-refresh-method"]')&.[]("content")).to eq("morph")
    expect(page.at_css('meta[name="turbo-refresh-scroll"]')&.[]("content")).to eq("preserve")
  end

  it "subscribes to the study's refresh stream" do
    get search_path(nct_id)

    expect(page.at_css("#prescreen turbo-cable-stream-source")).to be_present
  end

  it "offers to write the questions, without writing them on page load" do
    expect { get search_path(nct_id) }.not_to have_enqueued_job(GenerateStudyPrescreenJob)
    expect(page.at_css("#prescreen form[action='/prescreens/#{nct_id}']")).to be_present
  end

  it "is absent for a study with no criteria" do
    study.merge!(inclusion_criteria: nil, exclusion_criteria: nil)
    get search_path(nct_id)

    expect(page.at_css("#prescreen")).to be_nil
  end

  it "says the questions are being written" do
    create(:study_prescreen, nct_id: nct_id)
    get search_path(nct_id)

    expect(panel).to include("Writing questions from this study's criteria")
  end

  it "offers a retry after a failure" do
    create(:study_prescreen, nct_id: nct_id, status: "failed", error_message: "We couldn't write questions.")
    get search_path(nct_id)

    expect(panel).to include("We couldn't write questions.")
    expect(page.at_css("#prescreen form[action='/prescreens/#{nct_id}']")).to be_present
  end

  it "offers an update when the study has changed its criteria" do
    create(:study_prescreen, :completed, nct_id: nct_id, criteria_digest: "old")
    get search_path(nct_id)

    expect(panel).to include("changed its criteria")
    expect(panel).to include("Update the questions")
  end

  it "says when there is nothing a patient could answer" do
    current_prescreen(questions: [])
    get search_path(nct_id)

    expect(panel).to include("None of this study's criteria are things you could answer")
  end

  describe "with questions" do
    before { current_prescreen }

    it "shows each question with the study's own wording, read-only when signed out" do
      get search_path(nct_id)

      expect(panel).to include("Do you smoke?")
      expect(panel).to include("From the study: Current smokers")
      expect(panel).to include("Sign in to answer")
      expect(page.css("#prescreen form[action='/prescreens/#{nct_id}/answers']")).to be_empty
    end

    describe "signed in" do
      before { sign_in user }

      it "offers yes, no, and not sure on each question" do
        get search_path(nct_id)

        buttons = page.css("[data-question-key='q-1'] button").map { |b| b.text.squish }
        expect(buttons).to eq(["Yes", "No", "Not sure"])
      end

      it "marks the answer already given" do
        create(:prescreen_answer, user: user, nct_id: nct_id, question_key: "q-1", answer: "no")
        get search_path(nct_id)

        pressed = page.css("[data-question-key='q-1'] button[aria-pressed='true']").map { |b| b.text.squish }
        expect(pressed).to eq(["No"])
        expect(panel).to include("You have answered 1 of 2")
      end

      # End to end through the checklist: the smoking answer is self-reported,
      # so it rules the person out with the caveat attached.
      it "moves a ruling-out answer into what rules you out, with the caveat" do
        create(:prescreen_answer, user: user, nct_id: nct_id, question_key: "q-1", answer: "yes")
        get search_path(nct_id)

        eligibility = page.at_css("#eligibility").text.squish
        expect(eligibility).to include("What rules you out")
        expect(eligibility).to include("Do you smoke? You answered yes. #{EligibilityChecker::SELF_REPORTED_NOTE}")
      end

      it "answers and lands back on the same page, so Turbo morphs it in place" do
        post prescreen_answers_path(nct_id), params: {question_key: "q-0", answer: "yes"},
          headers: {"Referer" => "http://www.example.com#{search_path(nct_id)}?from=results"}

        expect(response).to redirect_to("http://www.example.com#{search_path(nct_id)}?from=results")
      end
    end
  end
end
