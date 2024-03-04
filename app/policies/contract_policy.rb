class ContractPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('contracts.create')
  end

  def update?
    user.has_permission?('contracts.update')
  end

  def destroy?
    user.has_permission?('contracts.destroy')
  end
end