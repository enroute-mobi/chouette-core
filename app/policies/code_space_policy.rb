class CodeSpacePolicy < ApplicationPolicy
  def create?
    workgroup_owner? && user.has_permission?('code_spaces.create')
  end

  def update?
    workgroup_owner? && user.has_permission?('code_spaces.update')
  end

  def destroy?
    false
    # workgroup_owner? && user.has_permission?('code_spaces.destroy')
  end

  def workgroup_owner?
    return true unless record.respond_to?(:workgroup)
    user.belongs_to_workgroup_owner? record&.workgroup
  end
end
