# == Schema Information
#
# Table name: profiles
#
#  id                      :bigint           not null, primary key
#  birth_year              :integer
#  city                    :string
#  contact_preference      :string
#  country                 :string           default("US")
#  current_treatment       :string
#  diagnosis_timing        :string
#  ethnicity               :string           default("prefer not to say")
#  first_name              :string
#  language_preference     :string
#  last_name               :string
#  onboarded               :boolean          default(FALSE), not null
#  onboarding_step         :integer          default(1), not null
#  phone_number            :string
#  prior_treatment         :boolean          default(FALSE)
#  pronouns                :string
#  remote_visit_preference :string
#  risk_tolerance          :string
#  sex_assigned_at_birth   :string
#  state                   :string
#  transportation_reliable :boolean          default(TRUE)
#  trial_type_preference   :string
#  willing_travel_miles    :integer
#  zip_code                :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  gender_id               :bigint
#  race_id                 :bigint
#  user_id                 :bigint           not null
#
# Indexes
#
#  index_profiles_on_gender_id  (gender_id)
#  index_profiles_on_race_id    (race_id)
#  index_profiles_on_user_id    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (gender_id => genders.id)
#  fk_rails_...  (race_id => races.id)
#  fk_rails_...  (user_id => users.id)
#

class Profile < ApplicationRecord
  # Pronouns
  HE_HIM = "he/him"
  SHE_HER = "she/her"
  THEY_THEM = "they/them"
  OTHER = "other"

  PRONOUN_OPTIONS = [HE_HIM, SHE_HER, THEY_THEM, OTHER].freeze

  # Sexes
  #
  # Only the two values ClinicalTrials.gov filters on. The registry expresses a
  # study's eligibility as ALL, FEMALE, or MALE, so anything else here cannot be
  # compared against a trial and gets read as a mismatch instead of a non-answer.
  #
  # "intersex" and "prefer not to say" used to be options and both disqualified
  # the user from every sex-restricted trial, while leaving the field blank did
  # not. Blank already means what "prefer not to say" was meant to mean: unknown,
  # scored neutral, never a gate. The field is optional, so declining is still
  # available and now actually works.
  FEMALE = "female"
  MALE = "male"
  PREFER_NOT_TO_SAY = "prefer not to say"

  SEX_ASSIGNED_AT_BIRTH_OPTIONS = [FEMALE, MALE].freeze

  # Ethnicity
  HISPANIC_OR_LATINO = "hispanic or latino"
  NOT_HISPANIC_OR_LATINO = "not hispanic or latino"

  ETHNICITY_OPTIONS = [HISPANIC_OR_LATINO, NOT_HISPANIC_OR_LATINO, PREFER_NOT_TO_SAY].freeze

  # Diagnosis Timings
  LESS_THAN_SIX_MONTHS = "< 6 months"
  SIX_TO_TWENTYFOUR_MONTHS = "6-24 months"
  GREATER_THAN_TWO_YEARS = "> 2 years"
  NOT_SURE = "not sure"

  DIAGNOSIS_TIMING_OPTIONS = [LESS_THAN_SIX_MONTHS, SIX_TO_TWENTYFOUR_MONTHS, GREATER_THAN_TWO_YEARS, NOT_SURE].freeze

  # Treatments
  NONE = "none"
  SURGERY = "surgery"
  CHEMOTHERAPY = "chemotherapy"
  RADIATION = "radiation"
  IMMUNOTHERAPY = "immunotherapy"
  ORAL_MEDICATION = "oral medication"

  TREATMENT_OPTIONS = [
    NONE,
    SURGERY,
    CHEMOTHERAPY,
    RADIATION,
    IMMUNOTHERAPY,
    ORAL_MEDICATION,
    OTHER
  ].freeze

  # Travel
  TEN_MILES = 10
  TWENTYFIVE_MILES = 25
  FIFTY_MILES = 50
  HUNDRED_MILES = 100

  TRAVEL_MILES_OPTIONS = [
    TEN_MILES,
    TWENTYFIVE_MILES,
    FIFTY_MILES,
    HUNDRED_MILES
  ].freeze

  # Remote Visit Preferences
  IN_PERSON_ONLY = "in-person only"
  HYBRID = "hybrid (some virtual visits)"
  REMOTE = "remote if possible"

  REMOTE_VISIT_PREFERENCE_OPTIONS = [
    IN_PERSON_ONLY,
    HYBRID,
    REMOTE
  ].freeze

  # Trial Type Preferences
  INTERVENTIONAL = "interventional"
  OBSERVATIONAL = "observational"
  EITHER = "either"

  TRIAL_TYPE_PREFERENCE_OPTIONS = [
    INTERVENTIONAL,
    OBSERVATIONAL,
    EITHER
  ].freeze

  # Risk Tolerances
  APPROVED_ONLY = "approved treatments only"
  TESTED = "tested in other patients"
  EARLY_STAGE_OKAY = "early-stage is okay"

  RISK_TOLERANCE_OPTIONS = [
    APPROVED_ONLY,
    TESTED,
    EARLY_STAGE_OKAY
  ].freeze

  # Contact Preferences
  EMAIL = "email"
  SMS = "sms"
  IN_APP = "in-app"

  CONTACT_PREFERENCE_OPTIONS = [
    EMAIL,
    SMS,
    IN_APP
  ].freeze

  belongs_to :user
  belongs_to :gender, optional: true
  belongs_to :race, optional: true

  has_many :profile_identities, dependent: :destroy
  # Ordered explicitly: SQLite happened to return these in rowid order, so the
  # profile page looked stable without an ORDER BY. Postgres makes no such
  # guarantee and the display order can shuffle between requests.
  has_many :identities, -> { order(:name) }, through: :profile_identities
  has_many :profile_interests, dependent: :destroy
  has_many :interests, -> { order(:name) }, through: :profile_interests
  has_many :profile_conditions, dependent: :destroy
  has_many :conditions, -> { order(:name) }, through: :profile_conditions

  accepts_nested_attributes_for :profile_conditions, allow_destroy: true,
    reject_if: proc { |attrs| attrs["condition_id"].blank? }

  # A select rendered with include_blank submits an empty string, not nil, and
  # the scorer reads these as "the user told us something". An empty
  # sex_assigned_at_birth scored 0 rather than the neutral 50, so declining to
  # answer in the wizard cost 20 points of weight. Same shape as the bugs fixed
  # in #96 and #97: answering, or declining to, was worse than never being asked.
  normalizes :sex_assigned_at_birth, :risk_tolerance, :trial_type_preference,
    :pronouns, :ethnicity, :diagnosis_timing, :current_treatment,
    :remote_visit_preference, :contact_preference, :language_preference,
    :city, :state, :zip_code,
    with: ->(value) { value.presence }

  # Set by the conditions step when someone has no diagnosis yet. Not stored:
  # it only tells the step's validation that an empty list was deliberate.
  attr_accessor :no_conditions

  has_one_attached :avatar
  has_rich_text :about

  validates :user_id, uniqueness: true
  # Each wizard step saves under its own context so a partial submission is not
  # rejected for fields the user has not reached yet. The :update context is
  # kept alongside so the full edit form behaves exactly as it did.
  validates :first_name, presence: true, on: [:update, :onboarding_identity]
  validates :last_name, presence: true, on: [:update, :onboarding_identity]
  validates :zip_code, presence: true, on: [:update, :onboarding_location]
  validates :birth_year, presence: true, on: :onboarding_basics
  validates :birth_year,
    numericality: {only_integer: true, greater_than_or_equal_to: 1900, less_than_or_equal_to: ->(_) { Time.current.year }},
    allow_blank: true
  validate :must_list_a_condition, on: :onboarding_conditions
  validates :pronouns, inclusion: {in: PRONOUN_OPTIONS}, allow_blank: true
  validates :sex_assigned_at_birth, inclusion: {in: SEX_ASSIGNED_AT_BIRTH_OPTIONS}, allow_blank: true
  validates :ethnicity, inclusion: {in: ETHNICITY_OPTIONS}, allow_blank: true
  validates :diagnosis_timing, inclusion: {in: DIAGNOSIS_TIMING_OPTIONS}, allow_blank: true
  validates :current_treatment, inclusion: {in: TREATMENT_OPTIONS}, allow_blank: true
  validates :willing_travel_miles, inclusion: {in: TRAVEL_MILES_OPTIONS}, allow_blank: true
  validates :remote_visit_preference, inclusion: {in: REMOTE_VISIT_PREFERENCE_OPTIONS}, allow_blank: true
  validates :trial_type_preference, inclusion: {in: TRIAL_TYPE_PREFERENCE_OPTIONS}, allow_blank: true
  validates :risk_tolerance, inclusion: {in: RISK_TOLERANCE_OPTIONS}, allow_blank: true
  validates :contact_preference, inclusion: {in: CONTACT_PREFERENCE_OPTIONS}, allow_blank: true
  validates :onboarded, inclusion: [true, false]

  # Onboarding asks for a zip code and TrialScorer#score_location needs city and
  # state. Nothing connected the two, so location scored a flat neutral 50 for
  # anyone who never opened the full edit form, and the willing_travel_miles
  # tiebreak never executed at all.
  #
  # Fills only what is blank, so a hand-typed city on the edit form wins. When
  # the zip changes on its own, both are re-resolved: someone who moves and
  # updates only their zip should not keep their old city.
  before_validation :resolve_city_and_state_from_zip

  # `onboarded` predates the wizard and is still read by the admin user list and
  # the user_onboarded? helper. Deriving it from progress keeps the two from
  # disagreeing without the controller having to remember to set it. Only ever
  # set true, so an admin toggling it off is not fought on the next save.
  before_save :flag_onboarded_once_required_steps_are_done

  def full_name
    "#{first_name} #{last_name}"
  end

  # Used by Utilities::AvatarComponent for the no-avatar fallback.
  def initials
    (first_name&.first&.upcase.to_s + last_name&.first&.upcase.to_s)
  end

  def age
    return nil unless birth_year.present?
    Time.current.year - birth_year
  end

  # The step the wizard should show, or nil once every step is behind them.
  def current_onboarding_step
    Onboarding.at(onboarding_step)
  end

  # Every required step is done, so the app is unlocked. Optional steps may
  # still be outstanding.
  def onboarding_unlocked?
    onboarding_step >= Onboarding.unlocked_number
  end

  # Every step is done, required or not. Controls the finish-your-profile nudge.
  def profile_completed?
    onboarding_step >= Onboarding.complete_number
  end

  private

  def flag_onboarded_once_required_steps_are_done
    self.onboarded = true if onboarding_unlocked?
  end

  def must_list_a_condition
    return if no_conditions == "1"
    return if profile_conditions.reject(&:marked_for_destruction?).any?

    errors.add(:base, "Add at least one condition, or tell us you do not have a diagnosis yet.")
  end

  def resolve_city_and_state_from_zip
    return if zip_code.blank?

    incomplete = city.blank? || state.blank?
    # A zip edited without touching city or state reads as a move.
    moved = zip_code_changed? && !city_changed? && !state_changed?
    return unless incomplete || moved

    match = ZipCode.lookup(zip_code)
    return if match.nil?

    self.city = match.city if city.blank? || moved
    self.state = match.state if state.blank? || moved
  end
end
