class WorkbenchPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def show?
    record.workgroup.organisations.exists?(id: user.organisation_id)
  end

  def update?
    organisation_match? && user.has_permission?('workbenches.update')
  end

  def organisation_match?
    record.organisation_id == user.organisation_id
  end
end
