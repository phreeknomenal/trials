class ApplicationController < ActionController::Base
  include Pagy::Backend
  include AuthenticationHelper

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  layout :layout

  private

  def layout
    user_validated? ? "application" : "unauthenticated"
  end

  def user_validated?
    user_signed_in? && current_profile.present? && current_profile.persisted?
  end
end
