module Admin
  class UsersController < BaseController
    include Paginatable

    def index
      authorize :admin, :access?

      # includes(:profile) matters -- the table reads profile data per row, so
      # without it this is one query per user.
      scope = User.includes(:profile).order(created_at: :desc)
      @pagy, @users = pagy(scope, limit: page_size)

      # How far accounts get, from the board. Three counts rather than three
      # loads of every user: the page shows 25 rows and this describes all of
      # them.
      @funnel = {
        "Onboarded" => Profile.where(onboarded: true).count,
        "Incomplete" => Profile.where(onboarded: false).count,
        "No profile" => User.where.missing(:profile).count
      }
    end

    private

    def default_page_size
      25
    end
  end
end
