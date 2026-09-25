class SavedTrialPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && record.user == user
  end

  def create?
    user.present?
  end

  def update?
    user.present? && record.user == user
  end

  def destroy?
    user.present? && record.user == user
  end

  # Authorised on the class, because a bulk update is about a set rather than
  # one record. Which records it may touch is settled by the scope: the action
  # resolves ids through policy_scope, so an id belonging to somebody else
  # simply is not found.
  def bulk_update?
    user.present?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end
end
