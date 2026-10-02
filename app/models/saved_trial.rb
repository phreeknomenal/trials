# == Schema Information
#
# Table name: saved_trials
#
#  id                   :bigint           not null, primary key
#  completion_date      :date
#  enrollment_count     :integer
#  match_score          :decimal(5, 2)
#  max_age              :integer
#  min_age              :integer
#  phase                :string
#  registry_checked_at  :datetime
#  registry_last_update :date
#  registry_status      :string
#  registry_why_stopped :text
#  seen_last_update     :date
#  sponsor              :string
#  start_date           :date
#  status               :string           default("interested"), not null
#  study_type           :string
#  summary              :text
#  tags                 :string
#  trial_status         :string
#  trial_title          :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  nct_id               :string           not null
#  user_id              :bigint           not null
#
# Indexes
#
#  index_saved_trials_on_created_at    (created_at)
#  index_saved_trials_on_status        (status)
#  index_saved_trials_on_user_and_nct  (user_id,nct_id) UNIQUE
#  index_saved_trials_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class SavedTrial < ApplicationRecord
  # In-memory attributes (not persisted to DB)
  attr_accessor :score_breakdown, :match_level

  # Status enum
  INTERESTED = "interested".freeze
  APPLYING = "applying".freeze
  CONTACTED = "contacted".freeze
  ENROLLED = "enrolled".freeze
  REJECTED = "rejected".freeze
  COMPLETED = "completed".freeze
  NOT_ELIGIBLE = "not_eligible".freeze

  STATUSES = [
    INTERESTED,
    APPLYING,
    CONTACTED,
    ENROLLED,
    REJECTED,
    COMPLETED,
    NOT_ELIGIBLE
  ].freeze

  belongs_to :user

  validates :nct_id, presence: true
  validates :user_id, presence: true
  validates :status, presence: true, inclusion: {in: STATUSES}
  validates :nct_id, uniqueness: {scope: :user_id, message: "already saved by this user"}

  has_rich_text :notes

  # How long a registry check stays good. Statuses move on a scale of weeks, and
  # the check is one API call per row, so once a day is plenty.
  RECHECK_AFTER = 24.hours

  scope :registry_stale, -> {
    where(registry_checked_at: nil).or(where(registry_checked_at: ...RECHECK_AFTER.ago))
  }

  # What the registry says now. update_columns, not update, because updated_at
  # is the person's own activity. The dashboard's "awaiting reply" panel reads it
  # as "nothing has moved", and a background check is not the person moving.
  #
  # The first check is the only point the registry date is known, so it becomes
  # the baseline rather than a change. trial_status needs no such step: it was
  # written at save time.
  def record_registry!(study)
    attributes = {
      registry_status: study[:status],
      registry_last_update: study[:last_update],
      registry_why_stopped: study[:why_stopped],
      registry_checked_at: Time.current
    }
    attributes[:seen_last_update] = study[:last_update] if seen_last_update.nil?

    update_columns(attributes)
  end

  # The person has now seen the latest, so it becomes the baseline. Called when
  # the saved study is opened, after the page has explained what changed.
  def acknowledge_registry!
    return unless registry_checked_at

    attributes = {seen_last_update: registry_last_update}
    attributes[:trial_status] = registry_status if registry_status.present?

    update_columns(attributes)
  end

  def tags_array
    tags.present? ? tags.split(",").map(&:strip) : []
  end

  def tags_array=(array)
    self.tags = array.reject(&:blank?).join(", ")
  end

  def add_tag(tag)
    current_tags = tags_array
    current_tags << tag unless current_tags.include?(tag.strip)
    self.tags_array = current_tags
  end

  def remove_tag(tag)
    current_tags = tags_array
    current_tags.delete(tag.strip)
    self.tags_array = current_tags
  end

  # Extract and store trial data from API response
  def populate_trial_data(study_hash)
    return unless study_hash.is_a?(Hash)

    self.phase = study_hash[:phase]
    self.study_type = study_hash[:study_type]
    self.trial_status = study_hash[:status]
    self.min_age = study_hash[:min_age]
    self.max_age = study_hash[:max_age]
    self.enrollment_count = study_hash[:enrollment_count]
    self.start_date = study_hash[:start_date]
    self.completion_date = study_hash[:completion_date]
    self.sponsor = study_hash[:sponsor]
    self.summary = study_hash[:summary]
  end
end
