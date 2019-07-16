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

  def remove_deletion?
    record.deleted_at.present? && destroy?
  end

  def setup_deletion?
    !record.deleted_at.present? && destroy?
  end
  
end
