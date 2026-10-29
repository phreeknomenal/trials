require "rails_helper"

RSpec.describe ProfileSections do
  let(:profile) { create(:user).profile }

  # The single form was broken into seven sections. If a field is in none of
  # them it silently stops being editable, and nothing else would notice.
  it "covers every field the old single form could write" do
    covered = described_class.all_permitted.flat_map { |p| p.is_a?(Hash) ? p.keys : p }.map(&:to_s)

    was_editable = %w[about birth_year city contact_preference country current_treatment
      diagnosis_timing ethnicity first_name gender_id language_preference last_name
      phone_number prior_treatment pronouns race_id remote_visit_preference risk_tolerance
      sex_assigned_at_birth state transportation_reliable trial_type_preference
      willing_travel_miles zip_code]

    expect(was_editable - covered).to be_empty
  end

  it "puts every field in exactly one section" do
    plain = described_class.all.flat_map(&:fields)

    expect(plain).to eq(plain.uniq)
  end

  # Conditions carry the largest single weight in TrialScorer::WEIGHTS, so the
  # label belongs on them rather than on Health.
  it "marks conditions as the largest factor and background as no factor" do
    expect(described_class.find("conditions").impact_label).to eq("Largest factor in matching")
    expect(described_class.find("background")).not_to be_affects_matching
  end

  describe "#complete?" do
    def complete?(slug, subject = profile) = described_class.new(subject).complete?(described_class.find(slug))

    it "is false for a section with nothing in it" do
      profile.update_columns(phone_number: nil, contact_preference: nil, language_preference: nil)

      expect(complete?("contact")).to be(false)
    end

    # The old rule. One answer out of several made a section look finished.
    it "is false while any checked question is still open" do
      profile.update_columns(trial_type_preference: Profile::EITHER, risk_tolerance: nil)

      expect(complete?("preferences")).to be(false)
    end

    it "counts a decline as an answer" do
      profile.update_columns(trial_type_preference: Profile::NO_PREFERENCE, risk_tolerance: Profile::NO_PREFERENCE)

      expect(complete?("preferences")).to be(true)
    end

    # An unticked checkbox saves false, and present? reads false as blank.
    it "counts a false checkbox as an answer" do
      profile.update_columns(willing_travel_miles: Profile::FIFTY_MILES,
        remote_visit_preference: Profile::HYBRID, transportation_reliable: false)

      expect(complete?("travel")).to be(true)
    end

    it "does not ask for a bio or a country" do
      profile.update_columns(first_name: "M", last_name: "B", pronouns: Profile::HE_HIM, country: nil)
      profile.update!(about: "")

      expect(complete?("about_you")).to be(true)
    end

    it "asks for a phone number only when texts are the preference" do
      profile.update_columns(contact_preference: Profile::SMS, language_preference: "English", phone_number: nil)
      expect(complete?("contact")).to be(false)

      profile.update_columns(contact_preference: Profile::EMAIL)
      expect(complete?("contact")).to be(true)
    end

    # Conditions are an association rather than a column, so the generic check
    # cannot see them.
    it "counts conditions as complete once one is listed" do
      profile.profile_conditions.destroy_all
      profile.update_columns(diagnosis_timing: nil)
      profile.conditions << Condition.create!(name: "Asthma")

      expect(complete?("conditions")).to be(true)
    end

    it "counts saying there is no diagnosis yet as answering conditions" do
      profile.profile_conditions.destroy_all
      profile.update_columns(diagnosis_timing: Profile::NO_DIAGNOSIS)

      expect(complete?("conditions", profile.reload)).to be(true)
    end
  end

  # The wizard sends a finished profile home, so every place that offers to fill
  # in a step has to point at the profile section instead.
  it "maps every wizard step to a profile section" do
    Onboarding.steps.each do |step|
      expect(described_class.for_step(step.slug)).to be_a(described_class::Section)
    end
  end

  # about is has_rich_text, and reading it like a column printed an entire HTML
  # document onto the page. Anything else that is not a plain column has to be
  # declared in ProfileFieldsHelper, or it will be stringified the same way.
  it "declares every field that is not a plain database column" do
    handled = ProfileFieldsHelper::RICH_TEXT.map(&:to_s) + ProfileFieldsHelper::ASSOCIATIONS.keys.map(&:to_s)
    not_columns = described_class.all.flat_map(&:fields).map(&:to_s) - Profile.column_names

    expect(not_columns - handled).to be_empty,
      "these are neither columns nor declared in ProfileFieldsHelper: #{(not_columns - handled).join(", ")}"
  end

  it "has a label for every field it renders" do
    fields = described_class.all.flat_map(&:fields)

    expect(fields - ProfileFieldsHelper::LABELS.keys).to be_empty
  end
end
