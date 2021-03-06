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
    !record.protected? && user.has_permission?('line_notices.destroy') && line_provider_matches?
  end

  def update?
    user.has_permission?('line_notices.update') && line_provider_matches?
  end

  def attach?
    user.has_permission?('line_notices.update')
  end

  def detach?
    attach?
  end
end
