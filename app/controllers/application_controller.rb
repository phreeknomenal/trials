class ApplicationController < ActionController::Base
  include Pagy::Method
  include Pundit::Authorization
  include AuthenticationHelper

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :ensure_profile_completed, if: :user_signed_in?

  # Without this, any failed `authorize` call raises and surfaces as a 500.
  # That gap predates the admin namespace -- SavedTrialsController and
  # ProfilesController already call authorize.
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  layout :layout

  private

  def user_not_authorized
    redirect_to root_path, alert: "You are not authorized to access that page."
  end

  def layout
    user_validated? ? "application" : "unauthenticated"
  end

  def user_validated?
    user_signed_in? && current_profile.present? && current_profile.persisted?
  end

  def ensure_profile_completed
    # Modal will be shown automatically if profile is incomplete
    # This allows users to navigate while still showing the modal
  end
end
