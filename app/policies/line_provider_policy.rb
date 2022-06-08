class LineProviderPolicy < ApplicationPolicy

  def create?
    user.has_permission?('line_providers.create')
  end

  def destroy?
    user.has_permission?('line_providers.destroy')
  end

  def update?
    user.has_permission?('line_providers.update')
  end

  # def has_permission?(permission)
  #   return false unless record.workbench_id == @current_workbench&.id
  #   return false if user && !user.has_permission?(permission)
  #   return false if @current_workbench && @current_workbench.has_restriction?(permission)
  #   true
  # end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
