class EntrancePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('entrances.create')
  end

  def destroy?
    user.has_permission?('entrances.destroy')
  end

  def update?
    user.has_permission?('entrances.update')
  end
end
