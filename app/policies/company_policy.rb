class CompanyPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    !archived? && organisation_match? && user.has_permission?('companies.create')
  end

  def update?
    !archived? && organisation_match? && user.has_permission?('companies.update')
  end

  def destroy?
    !archived? && organisation_match? && user.has_permission?('companies.destroy')
  end
end
