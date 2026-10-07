module Admin
  class OperationsController < BaseController
    def index
      authorize :admin, :access?

      @feeds = GenerationFeed.all
      @healthy = @feeds.all?(&:healthy?)
    end
  end
end
