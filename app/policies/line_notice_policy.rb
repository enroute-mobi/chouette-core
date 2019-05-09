class LineNoticePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('line_notices.create')
  end

  def destroy?
    user.has_permission?('line_notices.destroy')
  end

  def update?
    user.has_permission?('line_notices.update')
  end
end
