class ComplianceCheckSetPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def show?
    workgroup_owner? || inside_organisation?
  end

  def inside_organisation?
    record.workbench.organisation == user.organisation
  end

  def workgroup_owner?
    record.workgroup.owner == user.organisation
  end
end
