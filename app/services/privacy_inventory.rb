# The "what we collect" table on the privacy policy.
#
# It names real columns rather than describing them from memory, and a spec
# asserts every column on every model holding personal data belongs to some
# entry here. That is the point of the file: a privacy policy is the one page in
# an app that goes stale silently and harmfully. Add a column to `profiles` and
# nothing breaks, nothing warns, and the policy is quietly wrong about what the
# app holds.
#
# Same idea as the profile-sections guard from PR 7, which asserts no profile
# field lands in no section. There the cost of drift was a field nobody could
# edit; here it is a statement to patients that is no longer true.
class PrivacyInventory
  # `extras` is the things that are not columns: an Active Storage attachment, an
  # ActionText body, a join table. They are listed so the table reads
  # completely, and kept apart from `columns` because only a column can be
  # checked against a schema. Every entry passes it, including the empty ones,
  # so it has no default: a member reader on a Data class is defined on the
  # class itself rather than inherited, so there is no `super` to fall back to.
  Entry = Data.define(:title, :examples, :collected_when, :model_name, :columns, :extras)

  # Columns that are bookkeeping rather than information about a person. Each
  # one is skipped for a stated reason, so the list cannot quietly absorb
  # something that should have been disclosed.
  INTERNAL = {
    "id" => "row identifier",
    "created_at" => "row timestamp",
    "updated_at" => "row timestamp",
    "user_id" => "links a row to an account",
    "profile_id" => "links a row to a profile",
    "onboarded" => "whether the wizard was finished",
    "onboarding_step" => "how far through the wizard the account is",
    "role" => "member or admin, set by us and not by the person",
    "answered_at" => "whether we have replied yet"
  }.freeze

  ENTRIES = [
    Entry.new(
      title: "Your account",
      examples: "Email address, and a password stored as a hash rather than in readable form",
      collected_when: "Sign up",
      model_name: "User",
      columns: %w[email encrypted_password],
      extras: []
    ),

    Entry.new(
      title: "Keeping the account secure",
      examples: "Failed sign-in attempts, whether the account is locked, and the one-time tokens behind a password reset or an unlock",
      collected_when: "Signing in, resetting a password, unlocking an account",
      model_name: "User",
      columns: %w[failed_attempts locked_at unlock_token reset_password_token reset_password_sent_at remember_created_at],
      extras: []
    ),

    Entry.new(
      title: "Who you are",
      examples: "First and last name, pronouns, and a profile photo if you add one",
      collected_when: "The first onboarding step, and whenever you edit your profile",
      model_name: "Profile",
      columns: %w[first_name last_name pronouns],
      extras: ["Profile photo, stored as an uploaded file"]
    ),

    Entry.new(
      title: "Your health",
      examples: "Your conditions and which is primary, year of birth, sex assigned at birth, when you were diagnosed, and current and prior treatment",
      collected_when: "Onboarding, and whenever you edit your profile",
      model_name: "Profile",
      columns: %w[birth_year sex_assigned_at_birth diagnosis_timing current_treatment prior_treatment],
      extras: ["The conditions you selected"]
    ),

    Entry.new(
      title: "Where you are",
      examples: "ZIP code, and the city and state it resolves to. No street address is stored",
      collected_when: "The location onboarding step",
      model_name: "Profile",
      columns: %w[zip_code city state country],
      extras: []
    ),

    Entry.new(
      title: "How you would take part",
      examples: "How far you would travel, whether remote visits suit you, whether transport is reliable, and your trial type and risk preferences",
      collected_when: "The optional logistics and preferences steps",
      model_name: "Profile",
      columns: %w[willing_travel_miles remote_visit_preference transportation_reliable trial_type_preference risk_tolerance],
      extras: []
    ),

    Entry.new(
      title: "Background",
      examples: "Gender, race and ethnicity. Optional, and not used in matching",
      collected_when: "The optional about-you step",
      model_name: "Profile",
      columns: %w[gender_id race_id ethnicity],
      extras: []
    ),

    Entry.new(
      title: "Community",
      examples: "Identities and interests you picked. Optional, and not used in matching",
      collected_when: "The optional community step",
      model_name: "Profile",
      columns: [],
      extras: ["The identities you selected", "The interests you selected"]
    ),

    Entry.new(
      title: "How to reach you",
      examples: "Phone number, how you prefer to be contacted, preferred language, and anything you write in the free-text box about yourself",
      collected_when: "Your profile",
      model_name: "Profile",
      columns: %w[phone_number contact_preference language_preference],
      extras: ["What you write in the about box"]
    ),

    Entry.new(
      title: "Studies you saved",
      examples: "Which studies you saved, the status you set on each, your tags, your own notes, and the registry details of that study as they stood when you saved it",
      collected_when: "As you use the app",
      model_name: "SavedTrial",
      columns: %w[nct_id status tags match_score trial_title trial_status summary sponsor phase study_type
        enrollment_count min_age max_age start_date completion_date],
      extras: ["Your notes on a saved study"]
    ),

    Entry.new(
      title: "Messages you send us",
      examples: "The name, email address, subject and message you type into the contact form",
      collected_when: "The contact form",
      model_name: "ContactMessage",
      columns: %w[name email topic body],
      extras: []
    )
  ].freeze

  # The models the table claims to cover. Anything here is checked; anything not
  # here is out of scope and should be added deliberately.
  COVERED_MODELS = %w[User Profile SavedTrial ContactMessage].freeze

  class << self
    def entries = ENTRIES

    def columns_for(model_name)
      ENTRIES.select { |e| e.model_name == model_name }.flat_map(&:columns)
    end

    # Columns that exist on a covered model and appear in no entry and in no
    # internal exemption. The privacy spec asserts this is empty.
    def unlisted
      COVERED_MODELS.each_with_object({}) do |model_name, missing|
        actual = model_name.constantize.column_names
        gap = actual - columns_for(model_name) - INTERNAL.keys
        missing[model_name] = gap if gap.any?
      end
    end

    # Columns an entry names that the model does not have, which is the other
    # direction of the same drift: a rename leaves the policy describing
    # something the app stopped holding.
    def phantom
      COVERED_MODELS.each_with_object({}) do |model_name, extra|
        actual = model_name.constantize.column_names
        gap = columns_for(model_name) - actual
        extra[model_name] = gap if gap.any?
      end
    end
  end
end
