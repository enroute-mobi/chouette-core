class LineProviderPolicy < ApplicationPolicy

  def create?
    user.has_permission?('line_providers.create')
  end

  def destroy?
    user.has_permission?('line_providers.destroy') && current_workbench.line_providers.exists?(record.id)
  end

  def update?
    user.has_permission?('line_providers.update') && current_workbench.line_providers.exists?(record.id)
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
