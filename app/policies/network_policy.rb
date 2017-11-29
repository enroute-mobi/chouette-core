class NetworkPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('networks.create')
  end

  def update?
    user.has_permission?('networks.update')
  end

  def destroy?
    user.has_permission?('networks.destroy')
  end
end
