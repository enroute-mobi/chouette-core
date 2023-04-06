class ControlListPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def show
    workbench_matches?
  end

  def create?
    user.has_permission?('control_lists.create')
  end

  def destroy?
    user.has_permission?('control_lists.destroy') && workbench_matches? && without_processing_rules?
  end

  def update?
    user.has_permission?('control_lists.update') && workbench_matches?
  end

  def execute?
    user.has_permission?('control_list_runs.create')
  end

  def without_processing_rules?
    record.processing_rules.none?
  end
end
