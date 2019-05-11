class ConnectionLinkPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    !referential_read_only? && organisation_match? && user.has_permission?('connection_links.create')
    true
  end

  def destroy?
    !referential_read_only? && organisation_match? && user.has_permission?('connection_links.destroy')
    true
  end

  def update?
    !referential_read_only? && organisation_match? && user.has_permission?('connection_links.update')
    true
  end
end
