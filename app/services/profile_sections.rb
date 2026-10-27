# The profile as sections, each one editable on its own.
#
# It was a single 294 line form: every field on the page at once, one Save at the
# bottom, and no indication that answering one question changes every match score
# while answering another changes nothing at all. Editing a pronoun meant
# submitting a health history.
#
# The sections follow Onboarding::STEPS, so an answer given in the wizard is
# edited later in the same grouping, with three additions the wizard never asks
# for: the free-text fields, contact details, and the city and state that the ZIP
# lookup fills in.
class ProfileSections
  # How much a section changes what the app shows you. Stated on the section
  # rather than left to be inferred, because "sex assigned at birth" and
  # "pronouns" look equally personal and only one of them rules studies out.
  IMPACT = {
    primary: "Largest factor in matching",
    affects: "Affects how studies are ranked",
    none: "Does not affect matching"
  }.freeze

  # :context is the validation context a save runs under. Most sections use
  # :update; conditions borrows the wizard step's rule that an empty list needs
  # the "no diagnosis yet" box.
  Section = Data.define(:slug, :heading, :blurb, :impact, :fields, :permitted, :context) do
    def initialize(context: :update, **)
      super
    end

    def impact_label = IMPACT.fetch(impact)

    def affects_matching? = impact != :none
  end

  # :fields is what the section shows and edits. :permitted is what update will
  # accept for it, which is the same list plus the nested shapes strong params
  # needs spelled out.
  SECTIONS = [
    Section.new(
      slug: "about_you",
      heading: "About you",
      blurb: "Only used to address you in the app. Never sent to a study team.",
      impact: :none,
      fields: %i[first_name last_name pronouns about],
      # avatar rides with the names and pronouns, matching where the wizard now
      # collects it. It is not in :fields because it is rendered by its own
      # picker rather than through the generic field helper.
      permitted: %i[first_name last_name pronouns about avatar]
    ),
    Section.new(
      slug: "health",
      heading: "Health",
      blurb: "Age and sex are the two answers a study can rule you out on. Changing anything here rescores every match.",
      impact: :affects,
      fields: %i[birth_year sex_assigned_at_birth diagnosis_timing current_treatment prior_treatment],
      permitted: %i[birth_year sex_assigned_at_birth diagnosis_timing current_treatment prior_treatment]
    ),
    # Its own section rather than a line inside Health. It carries the largest
    # single weight, and it used to be editable only through a link into the
    # wizard, which sends anyone who has finished it back to the home page.
    Section.new(
      slug: "conditions",
      heading: "Conditions",
      blurb: "What you are looking for a study about. Changing this rescores every match.",
      impact: :primary,
      # Rendered by the wizard's conditions step, which handles the primary flag
      # and the no-diagnosis box, so there are no generic fields.
      fields: [],
      permitted: [:no_conditions, {profile_conditions_attributes: [:id, :condition_id, :is_primary, :_destroy]}],
      context: :onboarding_conditions
    ),
    Section.new(
      slug: "location",
      heading: "Location",
      blurb: "Your ZIP decides which study sites count as near you. No street address is stored.",
      impact: :affects,
      fields: %i[zip_code city state country],
      permitted: %i[zip_code city state country]
    ),
    Section.new(
      slug: "travel",
      heading: "Travel and visits",
      blurb: "Most studies need you on site. This decides how much a distant study loses.",
      impact: :affects,
      fields: %i[willing_travel_miles remote_visit_preference transportation_reliable],
      permitted: %i[willing_travel_miles remote_visit_preference transportation_reliable]
    ),
    Section.new(
      slug: "preferences",
      heading: "Study preferences",
      blurb: "Phase describes how much human testing has already happened.",
      impact: :affects,
      fields: %i[trial_type_preference risk_tolerance],
      permitted: %i[trial_type_preference risk_tolerance]
    ),
    Section.new(
      slug: "background",
      heading: "Background",
      blurb: "Helps studies report who takes part. It changes nothing about your matches.",
      impact: :none,
      fields: %i[race_id gender_id ethnicity],
      permitted: %i[race_id gender_id ethnicity]
    ),
    Section.new(
      slug: "community",
      heading: "What brings you here",
      blurb: "For finding people looking for the same things. It changes no score.",
      impact: :none,
      # Rendered by the wizard's community step, inline, so there are no generic
      # fields. It used to link into the wizard, which a finished profile cannot
      # reopen.
      fields: [],
      permitted: [{identity_ids: [], interest_ids: []}]
    ),
    Section.new(
      slug: "contact",
      heading: "How to reach you",
      blurb: "Used only if you ask a study team to get in touch.",
      impact: :none,
      fields: %i[phone_number contact_preference language_preference],
      permitted: %i[phone_number contact_preference language_preference]
    )
  ].freeze

  def self.all = SECTIONS

  def self.find(slug) = SECTIONS.find { |s| s.slug == slug.to_s }

  # Where each wizard step's answers are edited once the wizard is behind you.
  # The wizard redirects a finished profile home, so a link to a step is a dead
  # end for exactly the people most likely to follow it.
  STEP_SECTIONS = {
    "identity" => "about_you",
    "basics" => "health",
    "location" => "location",
    "conditions" => "conditions",
    "logistics" => "travel",
    "preferences" => "preferences",
    "about_you" => "background",
    "community" => "community",
    "contact" => "contact"
  }.freeze

  def self.for_step(step_slug) = find(STEP_SECTIONS.fetch(step_slug.to_s))

  # Every attribute any section can write. Used only to assert in a spec that no
  # field fell out of the page when the single form was broken up.
  def self.all_permitted = SECTIONS.flat_map(&:permitted)

  def initialize(profile)
    @profile = profile
  end

  attr_reader :profile

  # A section counts as answered when any of its own fields has a value.
  # Conditions live on an association rather than a column, so health asks that
  # separately.
  def answered_count = self.class.all.count { |section| answered?(section) }

  def total = self.class.all.length

  def percent = ((answered_count.to_f / total) * 100).round

  def answered?(section)
    case section.slug
    when "conditions" then profile.conditions.any? || profile.no_diagnosis?
    when "community" then profile.identities.any? || profile.interests.any?
    else section.fields.any? { |field| profile.public_send(field).present? }
    end
  end
end
