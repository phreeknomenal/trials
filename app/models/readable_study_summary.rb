# == Schema Information
#
# Table name: readable_study_summaries
#
#  id            :integer          not null, primary key
#  content       :text
#  error_message :text
#  generated_at  :datetime
#  status        :string           default("pending"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  nct_id        :string           not null
#
# Indexes
#
#  index_readable_study_summaries_on_nct_id  (nct_id) UNIQUE
#
class ReadableStudySummary < ApplicationRecord
  PENDING = "pending".freeze
  COMPLETED = "completed".freeze
  FAILED = "failed".freeze

  STATUSES = [
    PENDING,
    COMPLETED,
    FAILED
  ].freeze

  STALE_AFTER = 2.minutes

  NCT_ID_FORMAT = /\ANCT\d{8}\z/

  validates :nct_id, presence: true, uniqueness: true, format: {with: NCT_ID_FORMAT}
  validates :status, presence: true, inclusion: {in: STATUSES}

  def self.find_or_create_pending(nct_id)
    find_or_create_by!(nct_id: nct_id)
  rescue ActiveRecord::RecordNotUnique
    find_by!(nct_id: nct_id)
  end

  def pending?
    status == PENDING
  end

  def completed?
    status == COMPLETED
  end

  def failed?
    status == FAILED
  end

  def stale?
    pending? && updated_at < STALE_AFTER.ago
  end
end
