class ShapePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def update?
    has_permission?('shapes.update')
  end

  def destroy?
    has_permission?('shapes.destroy')
  end

  def has_permission?(permission)
    return false unless record.shape_provider.workbench_id == @current_workbench&.id
    return false if user && !user.has_permission?(permission)
    return false if @current_workbench && @current_workbench.has_restriction?(permission)
    true
  end

end
