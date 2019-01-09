class ImportPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(workbench_id: user.organisation.workbench_ids)
    end
  end

  def show?
    user.workgroups.pluck(:id).include?(record.workbench.workgroup_id)
  end

  def create?
    user.has_permission?('imports.create')
  end

  def update?
    user.has_permission?('imports.update')
  end
end
