class ApplicationController < ActionController::Base
  include Pagy::Backend
  include Pundit::Authorization
  include AuthenticationHelper

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :ensure_profile_completed, if: :user_signed_in?

  layout :layout

  private

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
