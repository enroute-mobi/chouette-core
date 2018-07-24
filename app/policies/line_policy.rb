class LinePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('lines.create')
  end

  def destroy?
    user.has_permission?('lines.destroy')
  end

  def deactivate?
    !record.deactivated? && user.has_permission?('lines.change_status')
  end

  def activate?
    record.deactivated? && user.has_permission?('lines.change_status')
  end

  def update?
    user.has_permission?('lines.update')
  end

end
