class LinePolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('lines.create')
  end

  def update?
    user.has_permission?('lines.update')
  end

  def destroy?
    user.has_permission?('lines.destroy')
  end
end
