class NetworkPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end
  def create?
    user.has_permission?('networks.create')
  end

  def destroy?
    user.has_permission?('networks.destroy') && line_provider_matches?
  end

  def update?
    user.has_permission?('networks.update') && line_provider_matches?
  end
end
