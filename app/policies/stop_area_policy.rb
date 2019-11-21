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
    user.has_permission?('stop_areas.destroy')
  end

  def update?
    user.has_permission?('stop_areas.update')
  end

  def deactivate?
    !record.deactivated? && user.has_permission?('stop_areas.change_status')
  end

  def activate?
    record.deactivated? && user.has_permission?('stop_areas.change_status')
  end
end
