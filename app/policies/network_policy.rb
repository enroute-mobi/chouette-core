class NetworkPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end
  def create?
    !archived? && organisation_match? && user.has_permission?('networks.create')
  end

  def update?
    !archived? && organisation_match? && user.has_permission?('networks.update')
  end

  def destroy?
    !archived? && organisation_match? && user.has_permission?('networks.destroy')
  end
end
