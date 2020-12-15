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
    user.has_permission?('stop_areas.destroy') && has_right_over_the_stop_area_provider?
  end

  def update?
    user.has_permission?('stop_areas.update') && has_right_over_the_stop_area_provider?
  end

  def deactivate?
    !record.deactivated? && user.has_permission?('stop_areas.change_status')
  end

  def activate?
    record.deactivated? && user.has_permission?('stop_areas.change_status')
  end
end
