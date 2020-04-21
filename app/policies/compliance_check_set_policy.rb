class ComplianceCheckSetPolicy < ApplicationPolicy
  class Scope < Scope
    # since CCS has now either workbench or workgroup as parent
    def resolve
      scope.where(workbench_id: user.organisation.workbench_ids).or(scope.where(workgroup_id: user.organisation.workgroup_ids))
    end
  end

  def show?
    user.organisation
    super || record.workbench.workgroup.owner == user.organisation
  end
end
