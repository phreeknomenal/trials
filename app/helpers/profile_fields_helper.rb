# One description of each profile field, used by both the read view and the edit
# form. Two lists would drift, and the drift would be silent: a field shown in
# one and not the other just quietly stops being editable.
module ProfileFieldsHelper
  LABELS = {
    first_name: "First name",
    last_name: "Last name",
    pronouns: "Pronouns",
    about: "About you",
    birth_year: "Year of birth",
    sex_assigned_at_birth: "Sex assigned at birth",
    diagnosis_timing: "Diagnosed",
    current_treatment: "Current treatment",
    prior_treatment: "Had prior treatment",
    zip_code: "ZIP code",
    city: "City",
    state: "State",
    country: "Country",
    willing_travel_miles: "Willing to travel",
    remote_visit_preference: "Remote visits",
    transportation_reliable: "Reliable transport",
    trial_type_preference: "Type of study",
    risk_tolerance: "Comfort with early stage",
    race_id: "Race",
    gender_id: "Gender",
    ethnicity: "Ethnicity",
    phone_number: "Phone",
    contact_preference: "Preferred contact",
    language_preference: "Language"
  }.freeze

  # Fields whose values come from a fixed list. Everything not here is free text,
  # a number, or a checkbox.
  OPTIONS = {
    pronouns: -> { Profile::PRONOUN_OPTIONS },
    sex_assigned_at_birth: -> { Profile::SEX_ASSIGNED_AT_BIRTH_OPTIONS },
    diagnosis_timing: -> { Profile::DIAGNOSIS_TIMING_OPTIONS },
    current_treatment: -> { Profile::TREATMENT_OPTIONS },
    willing_travel_miles: -> { Profile::TRAVEL_MILES_OPTIONS },
    remote_visit_preference: -> { Profile::REMOTE_VISIT_PREFERENCE_OPTIONS },
    trial_type_preference: -> { Profile::TRIAL_TYPE_PREFERENCE_OPTIONS },
    risk_tolerance: -> { Profile::RISK_TOLERANCE_OPTIONS },
    ethnicity: -> { Profile::ETHNICITY_OPTIONS },
    contact_preference: -> { Profile::CONTACT_PREFERENCE_OPTIONS }
  }.freeze

  BOOLEANS = %i[prior_treatment transportation_reliable].freeze

  NUMBERS = %i[birth_year].freeze

  ASSOCIATIONS = {race_id: Race, gender_id: Gender}.freeze

  # about is has_rich_text, so it is neither a column nor a text area: reading it
  # returns an ActionText::RichText whose to_s is a full HTML document, layout
  # comments and all.
  RICH_TEXT = %i[about].freeze

  def profile_field_label(field) = LABELS.fetch(field, field.to_s.humanize)

  def profile_field_args(form, field)
    args = {form: form, attribute: field, label: profile_field_label(field)}

    if ASSOCIATIONS.key?(field)
      args.merge(field_type: :select, select_options: ASSOCIATIONS[field].all.map { |r| [r.name, r.id] },
        options: {include_blank: "Prefer not to say"})
    elsif OPTIONS.key?(field)
      args.merge(field_type: :select, select_options: OPTIONS[field].call.map { |o| [o.to_s.humanize, o] },
        options: {include_blank: "Not answered"})
    elsif BOOLEANS.include?(field)
      args.merge(field_type: :checkbox)
    elsif NUMBERS.include?(field)
      args.merge(field_type: :number)
    elsif RICH_TEXT.include?(field)
      args.merge(field_type: :rich_text)
    else
      args.merge(field_type: :text)
    end
  end

  # "Not answered" rather than a blank cell, so an unanswered field reads as a
  # question still open rather than as a rendering fault.
  def profile_field_value(profile, field)
    if ASSOCIATIONS.key?(field)
      return unanswered_profile_field unless profile.public_send(field)

      return ASSOCIATIONS[field].find_by(id: profile.public_send(field))&.name || unanswered_profile_field
    end

    if RICH_TEXT.include?(field)
      body = profile.public_send(field)
      return unanswered_profile_field if body.blank?

      # Rendered as rich text rather than stringified. to_s here emits the
      # action_text layout, ERB comments included, which is what reached the page.
      return tag.div(body, class: "prose prose-sm dark:prose-invert max-w-none")
    end

    value = profile.public_send(field)

    if BOOLEANS.include?(field)
      # nil is a third state here: the question has not been answered, which is
      # not the same as answering no.
      return unanswered_profile_field if value.nil?

      return value ? "Yes" : "No"
    end

    return unanswered_profile_field if value.blank?

    # birth_year is the only field whose stored value is not what someone wants
    # to read back.
    return "#{value} · age #{profile.age}" if field == :birth_year && profile.age.present?

    value.to_s.humanize
  end

  def unanswered_profile_field
    tag.span("Not answered", class: "text-ink-4 dark:text-ink-4-on-dark")
  end
end
