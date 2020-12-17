class StopAreaPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('stop_areas.create')
  end

  def destroy?
    user.has_permission?('stop_areas.destroy') && stop_area_provider_matches?
  end

  def update?
    user.has_permission?('stop_areas.update') && stop_area_provider_matches?
  end
end
