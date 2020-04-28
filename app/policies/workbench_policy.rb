class WorkbenchPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def show?
    update?
  end

  def update?
    record.workgroup.owner == user.organisation && user.has_permission?('workbenches.update')
  end

  # TODO Enable workbench deletion / creation
  # def destroy?
  #   update?
  # end

  # def create?
  #   update?
  # end

end
