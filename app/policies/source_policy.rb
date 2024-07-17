class SourcePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('sources.create')
  end

  def destroy?
    user.has_permission?('sources.destroy')
  end

  def update?
    user.has_permission?('sources.update')
  end

  def retrieve?
    user.has_permission?('sources.retrieve')
  end

end
