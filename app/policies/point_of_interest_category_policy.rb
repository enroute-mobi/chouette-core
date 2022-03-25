class PointOfInterestCategoryPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('point_of_interest_categories.create')
  end

  def destroy?
    user.has_permission?('point_of_interest_categories.destroy')
  end

  def update?
    user.has_permission?('point_of_interest_categories.update')
  end
end
