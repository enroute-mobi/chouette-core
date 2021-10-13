class ComplianceCheckPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def show?
    ComplianceCheckSetPolicy.new(@user_context, @record.compliance_check_set).show?
  end

end
