class PointOfInterestPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('point_of_interests.create')
  end

  def destroy?
    user.has_permission?('point_of_interests.destroy')
  end

  def update?
    user.has_permission?('point_of_interests.update')
  end
end
