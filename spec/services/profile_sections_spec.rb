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

  it "marks health as the largest factor and background as no factor" do
    expect(described_class.find("health").impact_label).to eq("Largest factor in matching")
    expect(described_class.find("background")).not_to be_affects_matching
  end

  describe "#answered?" do
    it "is false for a section with nothing in it" do
      profile.update_columns(phone_number: nil, contact_preference: nil, language_preference: nil)

      expect(described_class.new(profile).answered?(described_class.find("contact"))).to be(false)
    end

    it "is true once any one field has a value" do
      profile.update_columns(phone_number: "205 555 0100", contact_preference: nil, language_preference: nil)

      expect(described_class.new(profile).answered?(described_class.find("contact"))).to be(true)
    end

    # Conditions are an association rather than a column, so the generic check
    # cannot see them.
    it "counts health as answered when there are conditions but no other field" do
      profile.update_columns(birth_year: nil, sex_assigned_at_birth: nil, diagnosis_timing: nil,
        current_treatment: nil, prior_treatment: nil)
      profile.conditions << Condition.create!(name: "Asthma")

      expect(described_class.new(profile).answered?(described_class.find("health"))).to be(true)
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
