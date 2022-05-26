class WorkgroupWorkbenchPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def show?
    workgroup.organisations.exists?(id: user.organisation_id)
  end

  def show_invitation_code?
    # Only users which can create a Workbench can see the invitation code
    create?
  end

  def update?
    workgroup_owner? && user.has_permission?('workbenches.update')
  end

  # TODO Enable workbench deletion / creation from workgroup admin section
  # def destroy?
  #   update?
  # end

  def create?
    workgroup_owner? && user.has_permission?('workbenches.create')
  end
end
