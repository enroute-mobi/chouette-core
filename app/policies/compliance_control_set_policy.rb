class ComplianceControlSetPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def show?
    own_or_workgroup_cc_set?
  end

  def destroy?
    own_cc_set? && user.has_permission?('compliance_control_sets.destroy')
  end

  def create?
    user.has_permission?('compliance_control_sets.create')
  end

  def update?
    own_cc_set? && user.has_permission?('compliance_control_sets.update')
  end

  def clone?
    own_or_workgroup_cc_set? && create?
  end

  def own_cc_set?
    @record.organisation == @user.organisation
  end

  def own_or_workgroup_cc_set?
    own_cc_set? || @user.workgroups.pluck(:owner_id).include?(@record.organisation.id)
  end
end
