# The lifecycle of a row a paid Claude call fills in, one per nct_id: pending
# until the job finishes, then completed or failed, with failed retryable.
#
# Shared by readable summaries and pre-screen questions. Constants live here
# and still resolve as ReadableStudySummary::PENDING, since Ruby looks up
# Klass::CONST through included modules.
module GeneratedPerStudy
  extend ActiveSupport::Concern

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

  included do
    validates :nct_id, presence: true, uniqueness: true, format: {with: NCT_ID_FORMAT}
    validates :status, presence: true, inclusion: {in: STATUSES}

    scope :pending, -> { where(status: PENDING) }
    scope :completed, -> { where(status: COMPLETED) }
    scope :failed, -> { where(status: FAILED) }

    # A pending record that has not moved in STALE_AFTER is a job that died
    # mid-run. This is the "generation is broken" signal -- a raw pending count
    # cannot tell a stuck record from one that started a second ago.
    scope :stale, -> { pending.where(updated_at: ...STALE_AFTER.ago) }

    scope :recent_first, -> { order(updated_at: :desc) }
  end

  class_methods do
    def find_or_create_pending(nct_id)
      find_or_create_by!(nct_id: nct_id)
    rescue ActiveRecord::RecordNotUnique
      find_by!(nct_id: nct_id)
    end
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
