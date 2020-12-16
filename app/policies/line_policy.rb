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
    user.has_permission?('lines.destroy') && line_provider_matches?
  end

  def update?
    user.has_permission?('lines.update') && line_provider_matches?
  end

  def update_activation_dates?
    user.has_permission?('lines.update_activation_dates')
  end
end
