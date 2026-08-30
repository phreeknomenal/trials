module Admin
  # Every admin controller inherits from this. Authentication runs before
  # authorization so a signed-out visitor is sent to sign-in rather than being
  # told the route exists.
  class BaseController < ApplicationController
    # ApplicationController picks its layout dynamically via `layout :layout`,
    # choosing between "application" and "unauthenticated" per request. This
    # static declaration overrides that for the whole namespace.
    layout "admin"

    before_action :authenticate_user!
    before_action :require_staff
    after_action :verify_authorized

    private

    def require_staff
      authorize :admin, :access?
    end
  end
end
