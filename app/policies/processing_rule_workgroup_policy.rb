class ProcessingRuleWorkgroupPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    Rails.logger.debug [ workgroup_owner?, user.has_permission?('processing_rules.create') ].inspect
    workgroup_owner? && user.has_permission?('processing_rules.create')
  end

  def destroy?
    workgroup_owner? && user.has_permission?('processing_rules.destroy')
  end

  def update?
    workgroup_owner? && user.has_permission?('processing_rules.update')
  end
end
