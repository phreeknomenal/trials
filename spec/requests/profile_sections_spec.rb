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

  # Both of these shipped in the first cut of this page and were spotted on
  # screen rather than by a test.
  describe "fields that are not ordinary columns" do
    # about is has_rich_text. Reading it returns an ActionText::RichText whose
    # to_s is a full HTML document, so the page printed the action_text layout
    # and its ERB comments as body copy.
    it "renders the about text as rich text, not as a stringified document" do
      profile.about = "<div>Something about me.</div>"
      profile.save!

      get profile_path(profile)

      expect(response.body).to include("Something about me.")
      expect(response.body).not_to include("begin app/views/layouts/action_text")
      expect(response.body).not_to include("trix-content\" class")
    end

    it "offers a rich text editor for it rather than a plain text area" do
      get profile_path(profile, section: "about_you")

      expect(response.body).to include("trix-editor")
    end

    it "says the about field is unanswered when it is empty" do
      get profile_path(profile)

      expect(response.body).to include("Not answered")
    end

    # AvatarComponent is w-full h-full by design; its own comment says the
    # wrapper governs layout. Rendered bare in a flex row it stretched into a
    # wide pill.
    it "gives the avatar a sized wrapper so it stays a circle" do
      get profile_path(profile)

      expect(response.body).to match(/w-14 h-14 shrink-0/)
    end
  end
end
