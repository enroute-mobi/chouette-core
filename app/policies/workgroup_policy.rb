class WorkgroupPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('workgroups.create')
  end

  def destroy?
    (record.owner == user.organisation) && user.has_permission?('workgroups.destroy')
  end

  def update?
    (record.owner == user.organisation) && user.has_permission?('workgroups.update')
  end

  def edit_controls?
    edit?
  end

  def update_controls?
    update?
  end

  def aggregate?
    update? && user.has_permission?('aggregates.create')
  end

  def setup_deletion?
    destroy?
  end

  def remove_deletion?
    destroy?
  end

  def add_workbench?
    user.has_permission?('workbenches.create')
  end

  def confirm?
    user.has_permission?('workbenches.confirm')
  end
end
