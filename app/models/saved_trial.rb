# == Schema Information
#
# Table name: saved_trials
#
#  id               :integer          not null, primary key
#  completion_date  :date
#  enrollment_count :integer
#  match_score      :decimal(5, 2)
#  max_age          :integer
#  min_age          :string
#  phase            :string
#  sponsor          :string
#  start_date       :date
#  status           :string           default("interested"), not null
#  study_type       :string
#  summary          :text
#  tags             :string
#  trial_status     :string
#  trial_title      :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  nct_id           :string           not null
#  user_id          :integer          not null
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
#  user_id  (user_id => users.id)
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
