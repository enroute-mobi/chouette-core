class StopAreaPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    !archived? && organisation_match? && user.has_permission?('stop_areas.create')
  end

  def update?
    !archived? && organisation_match? && user.has_permission?('stop_areas.update')
  end

  def destroy?
    !archived? && organisation_match? && user.has_permission?('stop_areas.destroy')
  end
end
