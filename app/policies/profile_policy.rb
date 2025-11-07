# frozen_string_literal: true

class ProfilePolicy < ApplicationPolicy
  def show?
    user_owns_profile?
  end

  def create?
    # User must be logged in and not have a profile yet
    user.present? && user.profile.nil?
  end

  def new?
    create?
  end

  def update?
    user_owns_profile?
  end

  def edit?
    update?
  end

  def destroy?
    false # Profiles should not be deleted
  end

  private

  def user_owns_profile?
    user.present? && record.user_id == user.id
  end
end
