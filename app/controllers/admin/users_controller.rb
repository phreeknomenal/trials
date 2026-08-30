module Admin
  class UsersController < BaseController
    include Paginatable

    def index
      authorize :admin, :access?

      # includes(:profile) matters -- the table reads profile data per row, so
      # without it this is one query per user.
      scope = User.includes(:profile).order(created_at: :desc)
      @pagy, @users = pagy(scope, limit: page_size)
    end

    private

    def default_page_size
      25
    end
  end
end
