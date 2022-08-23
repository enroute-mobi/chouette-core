# frozen_string_literal: true

class ProcessingRuleWorkbenchPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('processing_rules.create')
  end

  def destroy?
    user.has_permission?('processing_rules.destroy')
  end

  def update?
    user.has_permission?('processing_rules.update')
  end
end
