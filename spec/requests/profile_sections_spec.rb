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

    # The reported bug. "No preference" saved nil, the value a skipped question
    # saves, so the profile said "Not answered" to someone who had answered.
    it "reads back a no preference answer as no preference" do
      profile.update_columns(remote_visit_preference: Profile::NO_PREFERENCE,
        willing_travel_miles: Profile::NO_TRAVEL_PREFERENCE)

      get profile_path(profile)

      travel = Nokogiri::HTML(response.body).at_css("#travel")
      expect(travel.text).to include("No preference")
      expect(travel.text).not_to include("Not answered")
    end

    it "keeps a declined pronoun off the identity card" do
      profile.update_columns(pronouns: Profile::PREFER_NOT_TO_SAY, city: "Cleveland", state: "Ohio")

      get profile_path(profile)

      expect(Nokogiri::HTML(response.body).at_css("aside").text).not_to match(/prefer not to say/i)
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
    # The size is a design choice and may change; that there IS a sized,
    # non-shrinking wrapper is the thing that keeps it a circle.
    it "gives the avatar a sized wrapper so it stays a circle" do
      get profile_path(profile)

      expect(response.body).to match(/w-\d+ h-\d+ shrink-0/)
    end
  end

  # The board's left panel, which the first cut of this page was missing most of.
  describe "the side panel" do
    it "offers a way to change the photo from the page that shows it" do
      get profile_path(profile)

      expect(response.body).to include("Change photo")
    end

    it "shows profile strength as sections answered, not as a matching score" do
      get profile_path(profile)

      expect(response.body).to include("Profile strength")
      expect(response.body).to match(/\d+ of #{ProfileSections.all.length}/)
    end

    # It used to be hidden once every matching answer was in, which meant the
    # number vanished exactly when someone might want to confirm it.
    it "shows strength even when nothing is left to sharpen" do
      profile.update_columns(willing_travel_miles: 50, trial_type_preference: "either", risk_tolerance: "tested")

      get profile_path(profile)

      expect(response.body).to include("Profile strength")
      expect(response.body).to include("Everything that affects matching is answered")
    end

    # Sign-in details are the one thing on a profile that Devise owns rather than
    # Profile, so the panel links out rather than rendering a section for them.
    it "links to the account and email screen" do
      get profile_path(profile)

      expect(response.body).to include("Account and email")
      expect(response.body).to include(edit_user_registration_path)
    end

    it "lists every section in the nav" do
      get profile_path(profile)

      ProfileSections.all.each { |s| expect(response.body).to include("##{s.slug}") }
    end
  end

  # Both used to be a link into the wizard, which redirects a finished profile
  # to the home page, so neither could be changed at all after onboarding.
  describe "editing conditions and community in place" do
    let(:asthma) { Condition.create!(name: "asthma") }

    it "opens the conditions editor on the profile page" do
      get profile_path(profile, section: "conditions")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Add another condition")
      expect(response.body).not_to include(onboarding_step_path("conditions"))
    end

    it "adds a condition from the profile" do
      profile.profile_conditions.destroy_all

      patch profile_path(profile, section: "conditions"), params: {
        profile: {no_conditions: "0", profile_conditions_attributes: {"0" => {condition_id: asthma.id, is_primary: "1"}}}
      }

      expect(response).to redirect_to(profile_path(profile))
      expect(profile.reload.conditions).to contain_exactly(asthma)
    end

    it "refuses to empty the list without saying there is no diagnosis" do
      existing = profile.profile_conditions.first || profile.profile_conditions.create!(condition: asthma)

      patch profile_path(profile, section: "conditions"), params: {
        profile: {no_conditions: "0", profile_conditions_attributes: {"0" => {id: existing.id, _destroy: "1"}}}
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("tell us you do not have a diagnosis yet")
    end

    it "saves community choices from the profile" do
      interest = Interest.create!(name: "support groups")

      patch profile_path(profile, section: "community"), params: {profile: {interest_ids: ["", interest.id]}}

      expect(profile.reload.interests).to contain_exactly(interest)
    end

    it "opens the community editor on the profile page" do
      Interest.create!(name: "support groups")

      get profile_path(profile, section: "community")

      expect(response.body).to include("Support Groups")
      expect(response.body).not_to include(onboarding_step_path("community"))
    end
  end
end
