class SequencePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('sequences.create')
  end

  def update?
    user.has_permission?('sequences.update')
  end

  def destroy?
    user.has_permission?('sequences.destroy')
  end
end