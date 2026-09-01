require "rails_helper"

RSpec.describe "Onboarding wizard", type: :request do
  let(:user) { create(:user, :onboarding) }
  let(:profile) { user.profile }

  def step_path(slug) = onboarding_step_path(step: slug)

  before { sign_in user }

  describe "the gate" do
    # ApplicationController#ensure_profile_completed was an empty stub while a
    # CSS overlay did the blocking, so the app was gated in appearance only.
    it "redirects a signed-up user away from the app" do
      get saved_trials_path

      expect(response).to redirect_to(step_path("identity"))
    end

    it "sends them to the step they had reached, not back to the start" do
      profile.update_column(:onboarding_step, 3)

      get saved_trials_path

      expect(response).to redirect_to(step_path("location"))
    end

    it "lets a finished profile through" do
      sign_in create(:user)

      get saved_trials_path

      expect(response).to have_http_status(:ok)
    end

    it "lets a user through once the required steps are behind them" do
      profile.update_columns(onboarding_step: Onboarding.unlocked_number, onboarded: true)

      get saved_trials_path

      expect(response).to have_http_status(:ok)
    end

    # Without the devise_controller? exemption a half-onboarded user is trapped:
    # every page redirects into the wizard, including the one that signs them out.
    it "does not trap a user mid-wizard without a way to sign out" do
      get destroy_user_session_path

      expect(response).to redirect_to(root_path)
      get saved_trials_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "navigation" do
    it "sends the bare onboarding path to the current step" do
      get onboarding_path

      expect(response).to redirect_to(step_path("identity"))
    end

    it "refuses a forward jump past an unfinished step" do
      get step_path("conditions")

      expect(response).to redirect_to(step_path("identity"))
    end

    it "allows going back to an already-answered step" do
      profile.update_column(:onboarding_step, 3)

      get step_path("identity")

      expect(response).to have_http_status(:ok)
    end

    it "redirects an unknown step slug to the current one" do
      get step_path("nonsense")

      expect(response).to redirect_to(step_path("identity"))
    end

    it "sends a finished profile out of the wizard entirely" do
      sign_in create(:user)

      get step_path("identity")

      expect(response).to redirect_to(root_path)
    end
  end

  # Three of the four steps are only ever reached by redirect elsewhere in this
  # file, so nothing would notice a step whose component fails to render.
  describe "rendering" do
    it "renders every step" do
      Onboarding.steps.each do |step|
        profile.update_column(:onboarding_step, step.number)

        get step_path(step.slug)

        expect(response).to have_http_status(:ok), "#{step.slug} did not render"
        expect(response.body).to include(step.heading)
      end
    end

    it "shows progress out of the real step count" do
      get step_path("identity")

      expect(response.body).to include("Step 1 of #{Onboarding.count}")
    end
  end

  describe "submitting a step" do
    it "saves and advances to the next step" do
      patch step_path("identity"), params: {profile: {first_name: "Marques", last_name: "Bradley"}}

      expect(response).to redirect_to(step_path("basics"))
      expect(profile.reload).to have_attributes(first_name: "Marques", onboarding_step: 2)
    end

    # The whole reason for per-step validation contexts. Profile's presence
    # validations are declared on: :update, so without a context this submission
    # would be rejected for a blank zip code the user has not been asked for yet.
    it "does not reject a step for fields belonging to later steps" do
      patch step_path("identity"), params: {profile: {first_name: "Marques", last_name: "Bradley"}}

      expect(profile.reload.zip_code).to be_nil
      expect(response).to redirect_to(step_path("basics"))
    end

    it "re-renders the step on a validation error without advancing" do
      patch step_path("identity"), params: {profile: {first_name: "", last_name: ""}}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("First name can&#39;t be blank")
      expect(profile.reload.onboarding_step).to eq(1)
    end

    it "keeps progress when an earlier answer is corrected" do
      profile.update_column(:onboarding_step, 4)

      patch step_path("identity"), params: {profile: {first_name: "Corrected", last_name: "Name"}}

      expect(profile.reload).to have_attributes(first_name: "Corrected", onboarding_step: 4)
    end
  end

  describe "each step" do
    def complete_through(slug)
      payloads = {
        "identity" => {first_name: "Marques", last_name: "Bradley"},
        "basics" => {birth_year: 1986},
        "location" => {zip_code: "44106"},
        "conditions" => {no_conditions: "1"}
      }

      Onboarding.steps.each do |step|
        patch step_path(step.slug), params: {profile: payloads.fetch(step.slug)}
        break if step.slug == slug
      end
    end

    it "requires a birth year" do
      complete_through("identity")

      patch step_path("basics"), params: {profile: {birth_year: ""}}

      expect(response).to have_http_status(:unprocessable_entity)
    end

    # Blank is the decline path. #96 removed the two options that looked like
    # answers and disqualified the user from every sex-restricted study.
    it "accepts a blank sex, which is how a user declines to answer" do
      complete_through("identity")

      patch step_path("basics"), params: {profile: {birth_year: 1986, sex_assigned_at_birth: ""}}

      expect(response).to redirect_to(step_path("location"))
      expect(profile.reload.sex_assigned_at_birth).to be_nil
    end

    it "resolves city and state from the zip on the location step" do
      create(:zip_code, zip: "44106", city: "Cleveland", state: "Ohio")
      complete_through("basics")

      patch step_path("location"), params: {profile: {zip_code: "44106"}}

      expect(profile.reload).to have_attributes(city: "Cleveland", state: "Ohio")
    end

    it "requires a condition" do
      complete_through("location")

      patch step_path("conditions"), params: {profile: {profile_conditions_attributes: {}}}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Add at least one condition")
    end

    # Requiring a condition is right for matching and wrong for someone still
    # seeking a diagnosis. The app should not be a dead end for them.
    it "accepts an empty list when the user says they have no diagnosis yet" do
      complete_through("location")

      patch step_path("conditions"), params: {profile: {no_conditions: "1"}}

      expect(response).to redirect_to(root_path)
    end

    it "accepts a listed condition" do
      condition = Condition.create!(name: "asthma")
      complete_through("location")

      patch step_path("conditions"), params: {
        profile: {profile_conditions_attributes: {"0" => {condition_id: condition.id, is_primary: "1"}}}
      }

      expect(response).to redirect_to(root_path)
      expect(profile.reload.conditions).to include(condition)
    end
  end

  describe "finishing" do
    it "unlocks the app and lands on the root path" do
      Onboarding.steps.each do |step|
        payload = {
          "identity" => {first_name: "M", last_name: "B"},
          "basics" => {birth_year: 1986},
          "location" => {zip_code: "44106"},
          "conditions" => {no_conditions: "1"}
        }.fetch(step.slug)

        patch step_path(step.slug), params: {profile: payload}
      end

      expect(response).to redirect_to(root_path)
      expect(profile.reload).to have_attributes(onboarded: true, onboarding_step: Onboarding.complete_number)
      expect(profile).to be_profile_completed

      get saved_trials_path
      expect(response).to have_http_status(:ok)
    end
  end
end
