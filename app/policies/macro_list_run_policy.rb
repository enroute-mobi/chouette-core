class MacroListRunPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('macro_list_runs.create')
  end

  def destroy?
    false
  end

  def update?
    false
  end
end
