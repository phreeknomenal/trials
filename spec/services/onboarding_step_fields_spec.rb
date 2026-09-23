require "rails_helper"

# Where each answer is collected, asserted rather than left to whichever step a
# field drifted into.
RSpec.describe "Onboarding step grouping" do
  def step(slug) = Onboarding.steps.find { |s| s.slug == slug }

  def permits?(slug, field)
    step(slug).permitted.flat_map { |p| p.is_a?(Hash) ? p.keys : p }.include?(field)
  end

  # Pronouns and a photo are how to address someone and how they appear, which
  # is the question step one already asks. On about_you they sat among
  # demographics they have nothing to do with, and the photo was the tallest
  # thing on a step that was already too long.
  describe "identity" do
    it "collects the name, the pronouns and the photo" do
      %i[first_name last_name pronouns avatar].each do |field|
        expect(permits?("identity", field)).to be(true), "identity should permit #{field}"
      end
    end
  end

  describe "about_you" do
    it "collects demographics and community, and nothing about how you are addressed" do
      %i[gender_id race_id ethnicity].each do |field|
        expect(permits?("about_you", field)).to be(true), "about_you should permit #{field}"
      end

      expect(permits?("about_you", :pronouns)).to be(false)
      expect(permits?("about_you", :avatar)).to be(false)
    end
  end

  # basics carries 40 of the 100 scoring points and its prompt is about ruling
  # studies out. A field that changes no score does not belong in it.
  describe "basics" do
    it "stays to the two criteria a study can rule you out on" do
      expect(step("basics").permitted).to contain_exactly(:birth_year, :sex_assigned_at_birth)
    end
  end

  it "collects every field exactly once across the wizard" do
    plain = Onboarding.steps.flat_map { |s| s.permitted.flat_map { |p| p.is_a?(Hash) ? p.keys : p } }

    expect(plain).to eq(plain.uniq)
  end

  # The wizard and the profile have to agree, or an answer given in one is
  # edited somewhere unrelated in the other.
  describe "agreeing with the profile page" do
    it "keeps pronouns and the photo with the names in both" do
      about = ProfileSections.find("about_you")
      permitted = about.permitted.flat_map { |p| p.is_a?(Hash) ? p.keys : p }

      expect(permitted).to include(:pronouns, :avatar)
      expect(about.fields).to include(:first_name, :last_name, :pronouns)
    end

    it "keeps the photo out of the background section" do
      background = ProfileSections.find("background")
      permitted = background.permitted.flat_map { |p| p.is_a?(Hash) ? p.keys : p }

      expect(permitted).not_to include(:avatar)
    end
  end

  # Split from one step: demographics and community are different questions with
  # different reasons for asking, and together they could not fit a screen.
  describe "the split" do
    it "keeps demographics and community apart" do
      expect(permits?("about_you", :gender_id)).to be(true)
      expect(permits?("about_you", :identity_ids)).to be(false)

      expect(permits?("community", :identity_ids)).to be(true)
      expect(permits?("community", :interest_ids)).to be(true)
      expect(permits?("community", :gender_id)).to be(false)
    end

    it "leaves both optional, so neither can block the app" do
      expect(step("about_you")).not_to be_required
      expect(step("community")).not_to be_required
    end

    # unlocked_number is required_count + 1, so an extra optional step cannot
    # gate anyone who has already finished the required ones.
    it "does not move the point at which the app unlocks" do
      expect(Onboarding.unlocked_number).to eq(Onboarding.steps.count(&:required?) + 1)
    end
  end

  # Every count and label on the wizard is derived, so splitting a step cannot
  # leave "7 questions" on a screen that now has eight.
  it "counts its own steps rather than stating a number" do
    expect(Onboarding.count).to eq(Onboarding.steps.length)
  end
end
