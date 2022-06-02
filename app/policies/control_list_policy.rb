class ControlListPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def show
    current_workbench.control_lists.exists?(record.id)
  end

  def create?
    user.has_permission?('control_lists.create')
  end

  def destroy?
    user.has_permission?('control_lists.destroy') && current_workbench.control_lists.exists?(record.id)
  end

  def update?
    user.has_permission?('control_lists.update') && current_workbench.control_lists.exists?(record.id)
  end

  def execute?
     user.has_permission?('control_list_runs.create')
  end
end
