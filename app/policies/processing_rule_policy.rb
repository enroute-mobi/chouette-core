class ProcessingRulePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create_workgroup_rule?
    belongs_to_workgroup_owner?
  end

  def create?
    user.has_permission?('processing_rules.create')
  end

  def destroy?
    permission_for_workgroup_rule && user.has_permission?('processing_rules.destroy')
  end

  def update?
    permission_for_workgroup_rule && user.has_permission?('processing_rules.update')
  end

  private

  def permission_for_workgroup_rule
    return true unless record.workgroup_rule
     
    belongs_to_workgroup_owner?
  end

  def belongs_to_workgroup_owner?
    workbench.organisation_id === workbench.workgroup.owner_id
  end
end
