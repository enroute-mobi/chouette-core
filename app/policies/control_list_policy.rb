class ControlListPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('control_lists.create')
  end

  def destroy?
    user.has_permission?('control_lists.destroy')
  end

  def update?
    user.has_permission?('control_lists.update')
  end

  def execute?
     user.has_permission?('control_list_runs.create')
  end
end
