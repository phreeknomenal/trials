require "rails_helper"

RSpec.describe "The dashboard", type: :request do
  let(:user) { create(:user) }

  # This page had no request spec at all before this PR. A return type change in
  # TrialRecommendationService broke it for exactly the users who have
  # recommendations, and the whole suite stayed green, because the only fixture
  # reaching the page produced an empty result.
  def stub_recommendations(studies: [], status: :ok)
    allow(TrialRecommendationService).to receive(:new).and_return(
      instance_double(TrialRecommendationService,
        recommend: TrialRecommendationService::Result.new(studies: studies, status: status))
    )
  end

  def a_study
    {nct_id: "NCT1", title: "A recommended study", trial_score: 88, match_level: "excellent",
     status: "RECRUITING", phase: "PHASE2", conditions: ["Asthma"], locations: [],
     score_breakdown: {age: 100, sex: 100, conditions: 100, location: 100, study_type: 50, phase_risk: 50}}
  end

  before { sign_in user }

  it "renders with nothing on it" do
    stub_recommendations
    get my_trials_root_path
    expect(response).to have_http_status(:ok)
  end

  it "renders the recommendations it is given" do
    stub_recommendations(studies: [a_study])
    get my_trials_root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("A recommended study")
  end

  # The four outcomes that used to be one empty array.
  describe "when there is nothing to recommend" do
    it "says the registry was unreachable, rather than that nothing matches" do
      stub_recommendations(status: :unavailable)
      get my_trials_root_path
      expect(response.body).to include("could not reach the study registry")
      expect(response.body).not_to include("Nothing is recruiting that scores high enough")
    end

    it "says nothing scored high enough when that is what happened" do
      stub_recommendations(status: :none_matched)
      get my_trials_root_path
      expect(response.body).to include("Nothing is recruiting that scores high enough")
      expect(response.body).not_to include("could not reach")
    end

    it "asks for a condition when the profile has none" do
      stub_recommendations(status: :no_condition)
      get my_trials_root_path
      expect(response.body).to include("Matching starts with a condition")
    end
  end

  describe "saved studies" do
    before { stub_recommendations }

    it "shows the shape of the page before anything is saved" do
      get my_trials_root_path
      expect(response.body).to include("Nothing saved yet")
    end

    # Grouped by status, which is what the person controls, rather than by score
    # tier, which each card already shows.
    it "counts saved studies by status" do
      create(:saved_trial, user: user, status: SavedTrial::CONTACTED)
      create(:saved_trial, user: user, status: SavedTrial::INTERESTED)

      get my_trials_root_path

      expect(response.body).to include("Contacted")
      expect(response.body).to include("Interested")
    end

    it "offers comparison only once there are two to compare" do
      create(:saved_trial, user: user)
      get my_trials_root_path
      expect(response.body).not_to include("Compare saved studies")

      create(:saved_trial, user: user)
      get my_trials_root_path
      expect(response.body).to include("Compare saved studies")
    end
  end

  describe "waiting on a reply" do
    before { stub_recommendations }

    it "raises a study that has sat in contacted with no change" do
      saved = create(:saved_trial, user: user, status: SavedTrial::CONTACTED)
      saved.update_column(:updated_at, 10.days.ago)

      get my_trials_root_path

      expect(response.body).to include("Waiting on a reply")
    end

    it "leaves a recently updated one alone" do
      create(:saved_trial, user: user, status: SavedTrial::CONTACTED)

      get my_trials_root_path

      expect(response.body).not_to include("Waiting on a reply")
    end

    # Interested is not a conversation, so nothing is owed back.
    it "ignores a study nobody has contacted anyone about" do
      saved = create(:saved_trial, user: user, status: SavedTrial::INTERESTED)
      saved.update_column(:updated_at, 30.days.ago)

      get my_trials_root_path

      expect(response.body).not_to include("Waiting on a reply")
    end
  end

  # The panel used to hold one static block once a profile was matching-complete,
  # because the only other thing on it hid itself at exactly that point.
  describe "the side panel" do
    before { stub_recommendations }

    it "always says how complete the profile is" do
      get my_trials_root_path

      expect(response.body).to include("Your profile")
      expect(response.body).to match(/\d+ of #{ProfileSections.all.length}/)
    end

    it "still says so when nothing is left to sharpen" do
      user.profile.update_columns(willing_travel_miles: 50, trial_type_preference: "either", risk_tolerance: "tested")

      get my_trials_root_path

      expect(response.body).to include("Your profile")
      expect(response.body).to include("Everything that affects matching is answered")
    end

    it "names what would sharpen matching when something is missing" do
      user.profile.update_columns(willing_travel_miles: nil, remote_visit_preference: nil,
        trial_type_preference: nil, risk_tolerance: nil)

      get my_trials_root_path

      expect(response.body).to include("would sharpen your matches")
      expect(response.body).to include("How far would you travel?")
    end

    # Reported by the profile page too, and from the same object, so the two
    # cannot disagree about how complete a profile is.
    it "counts the same sections the profile page counts" do
      get my_trials_root_path
      dashboard = response.body[/(\d+) of #{ProfileSections.all.length}/, 1]

      get profile_path(user.profile)
      profile_page = response.body[/(\d+) of #{ProfileSections.all.length}/, 1]

      expect(dashboard).to eq(profile_page)
    end

    it "offers comparison in the panel once there are two to compare" do
      create_list(:saved_trial, 2, user: user)

      get my_trials_root_path

      expect(response.body).to include("Compare studies")
      expect(response.body).to include("Put two or three side by side")
    end
  end
end
