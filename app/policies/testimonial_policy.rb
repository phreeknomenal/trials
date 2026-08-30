# frozen_string_literal: true

class TestimonialPolicy < ApplicationPolicy
  def index? = staff?

  def show? = staff?

  def create? = staff?

  def new? = create?

  def update? = staff?

  def edit? = update?

  def destroy? = staff?

  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.staff? ? scope.all : scope.none
    end
  end

  private

  def staff?
    user.present? && user.staff?
  end
end
