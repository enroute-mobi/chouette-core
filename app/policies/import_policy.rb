class ImportPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    !archived? && user.has_permission?('imports.create')
  end

  def destroy?
    !archived? && user.has_permission?('imports.destroy')
  end

  def update?
    !archived? && user.has_permission?('imports.update')
  end
end
