class WorkbenchPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def show?
    user.organisation_id == record.workgroup.owner_id
  end

  def update?
    organisation_match? && user.has_permission?('workbenches.update')
  end
end
