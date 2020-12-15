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
    user.has_permission?('connection_links.destroy') && has_right_over_the_stop_area_provider?
  end

  def update?
    user.has_permission?('connection_links.update') && has_right_over_the_stop_area_provider?
  end
end
