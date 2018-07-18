class ComplianceControlPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def destroy?
    can_update_control_set? && user.has_permission?('compliance_controls.destroy')
  end

  def create?
    user.has_permission?('compliance_controls.create')
  end

  def update?
    can_update_control_set? && user.has_permission?('compliance_controls.update')
  end

  def can_update_control_set?
    ComplianceControlSetPolicy.new(@user_context, @record.compliance_control_set).update?
  end

end
