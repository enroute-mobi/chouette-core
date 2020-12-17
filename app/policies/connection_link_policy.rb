class ConnectionLinkPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('connection_links.create')
  end

  def destroy?
    user.has_permission?('connection_links.destroy') && stop_area_provider_matches?
  end

  def update?
    user.has_permission?('connection_links.update') && stop_area_provider_matches?
  end
end
