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
#  gender_id               :integer
#  race_id                 :integer
#  user_id                 :integer          not null
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
  FEMALE = "female"
  MALE = "male"
  INTERSEX = "intersex"
  PREFER_NOT_TO_SAY = "prefer not to say"

  SEX_ASSIGNED_AT_BIRTH_OPTIONS = [FEMALE, MALE, INTERSEX, PREFER_NOT_TO_SAY].freeze

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
  has_many :identities, through: :profile_identities
  has_many :profile_interests, dependent: :destroy
  has_many :interests, through: :profile_interests
  has_many :profile_conditions, dependent: :destroy
  has_many :conditions, through: :profile_conditions

  accepts_nested_attributes_for :profile_conditions, allow_destroy: true,
    reject_if: proc { |attrs| attrs["condition_id"].blank? }

  has_one_attached :avatar
  has_rich_text :about

  validates :user_id, uniqueness: true
  validates :first_name, presence: true, on: :update
  validates :last_name, presence: true, on: :update
  validates :zip_code, presence: true, on: :update
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

  def full_name
    "#{first_name} #{last_name}"
  end

  def age
    return nil unless birth_year.present?
    Time.current.year - birth_year
  end

  def profile_completed?
    return false unless onboarded?

    required_fields = %i[first_name last_name zip_code]
    required_fields.all? { |field| send(field).present? }
  end
end
