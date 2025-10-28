module Secured
  extend ActiveSupport::Concern
  def current_profile
    @current_profile ||= current_user&.profile
  end

  private

  def authenticate_admin_user!
    redirect_to root_path unless current_user.super_admin? || current_user.admin?
  end
end
