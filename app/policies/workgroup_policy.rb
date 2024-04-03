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
  alias edit_aggregate? update?
  alias edit_merge? update?
  alias edit_transport_modes? update?

  def aggregate?
    update? && user.has_permission?('aggregates.create')
  end

  def setup_deletion?
    destroy?
  end

  def remove_deletion?
    destroy?
  end

  # FIXME Required only by Workgroup decorator and associated action :-/
  def add_workbench?
    WorkgroupWorkbenchPolicy.new(@user_context, Workbench).create?
  end

  # FIXME Required only by Workgroup decorator and associated action :-/
  def confirm?
    WorkbenchConfirmationPolicy.new(@user_context, Workbench::Confirmation).create?
  end
end
