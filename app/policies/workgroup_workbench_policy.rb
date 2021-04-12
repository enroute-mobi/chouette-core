class WorkgroupWorkbenchPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def show?
    record.workgroup.orgnisation_ids.include?(user.organisation_id)
  end

  def update?
    record.workgroup.owner_id == user.organisation_id && user.has_permission?('workbenches.update')
  end

  # TODO Enable workbench deletion / creation from workgroup admin section
  # def destroy?
  #   update?
  # end

  # def create?
  #   update?
  # end

end
