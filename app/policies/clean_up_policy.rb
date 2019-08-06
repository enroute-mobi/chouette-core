class CleanUpPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.joins(:referential).where({referentials: { workbench_id: user.organisation.workbench_ids}})
    end

  end

  def show?
    user.organisation
    super || record.referential.workbench.workgroup.owner == user.organisation
  end
end
