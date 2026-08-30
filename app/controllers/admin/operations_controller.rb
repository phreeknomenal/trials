module Admin
  class OperationsController < BaseController
    def index
      authorize :admin, :access?

      @failed = ReadableStudySummary.failed.recent_first
      @stale = ReadableStudySummary.stale.recent_first
      @pending = ReadableStudySummary.pending.where.not(id: @stale.select(:id)).recent_first
      @completed_count = ReadableStudySummary.completed.count
    end
  end
end
