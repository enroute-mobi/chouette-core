class StopAreaPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('stop_areas.create')
  end

  def update?
    user.has_permission?('stop_areas.update')
  end

  def destroy?
    user.has_permission?('stop_areas.destroy')
  end

end
