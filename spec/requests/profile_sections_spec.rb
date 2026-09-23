require "rails_helper"

RSpec.describe "The profile page", type: :request do
  let(:user) { create(:user) }
  let(:profile) { user.profile }

  before { sign_in user }

  describe "reading it" do
    it "renders every section" do
      get profile_path(profile)

      expect(response).to have_http_status(:ok)
      ProfileSections.all.each { |s| expect(response.body).to include(s.heading) }
    end

    # "Sex assigned at birth" and "pronouns" look equally personal, and only one
    # of them rules studies out. The page says which.
    it "says how much each section affects matching" do
      get profile_path(profile)

      expect(response.body).to include("Largest factor in matching")
      expect(response.body).to include("Does not affect matching")
    end

    # A blank cell reads as a rendering fault. An unanswered question should read
    # as a question still open.
    it "says a field is unanswered rather than leaving it blank" do
      profile.update_columns(phone_number: nil)

      get profile_path(profile)

      expect(response.body).to include("Not answered")
    end

    it "shows the year of birth as an age too" do
      get profile_path(profile)

      expect(response.body).to match(/age \d+/)
    end
  end

  describe "editing one section" do
    it "opens only the section asked for" do
      get profile_path(profile, section: "location")

      expect(response.body).to include("Save location")
      expect(response.body).not_to include("Save health")
    end

    it "saves it and says which section was saved" do
      patch profile_path(profile, section: "location"), params: {profile: {city: "Huntsville"}}

      expect(response).to redirect_to(profile_path(profile))
      follow_redirect!
      expect(response.body).to include("Location saved")
      expect(profile.reload.city).to eq("Huntsville")
    end

    # A form showing five fields should not be able to write twenty-five.
    it "refuses fields belonging to another section" do
      original = profile.birth_year

      patch profile_path(profile, section: "location"),
        params: {profile: {city: "Huntsville", birth_year: 1900}}

      expect(profile.reload.birth_year).to eq(original)
      expect(profile.city).to eq("Huntsville")
    end

    it "warns that saving a matching section rescores everything" do
      get profile_path(profile, section: "health")

      expect(response.body).to include("Saving rescores every study")
    end

    it "does not warn on a section that changes no score" do
      get profile_path(profile, section: "contact")

      expect(response.body).not_to include("Saving rescores every study")
    end

    it "sends the old edit route to the page with that section open" do
      get edit_profile_path(profile, section: "travel")

      expect(response).to redirect_to(profile_path(profile, section: "travel"))
    end
  end

  # A profile is created with the account, so this is only reached when one has
  # gone missing.
  describe "a missing profile" do
    it "restores it and hands over to the wizard rather than a second long form" do
      user.profile.destroy
      user.reload

      get new_profile_path

      expect(response).to redirect_to(onboarding_path)
      expect(user.reload.profile).to be_present
    end

    it "sends someone who already has one back to their profile" do
      get new_profile_path

      expect(response).to redirect_to(profile_path(profile))
    end
  end
end
