class StopAreaReferentialPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def edit?
    workgroup_owner? && update?
  end

  def update?
    workgroup_owner? && instance_permission("update")
  end

  private

  def workgroup_owner?
    record.workgroup.owner == user.organisation
  end

  def instance_permission permission
    user.has_permission?("stop_area_referentials.#{permission}")
  end
end
