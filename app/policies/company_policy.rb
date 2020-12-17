class CompanyPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('companies.create')
  end

  def destroy?
    user.has_permission?('companies.destroy') && line_provider_matches?
  end

  def update?
    user.has_permission?('companies.update') && line_provider_matches?
  end
end
