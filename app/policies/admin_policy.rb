# frozen_string_literal: true

# Headless policy gating access to the whole Admin namespace.
# Used as `authorize :admin, :access?`.
class AdminPolicy < ApplicationPolicy
  def access?
    user.present? && user.staff?
  end
end
