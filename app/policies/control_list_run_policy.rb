class ControlListRunPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('control_list_runs.create')
  end

  def destroy?
    false
  end

  def update?
    false
  end
end
