class StopAreaProviderPolicy < ApplicationPolicy

  def create?
    user.has_permission?('stop_area_providers.create')
  end

  def destroy?
    user.has_permission?('stop_area_providers.destroy') && record.stop_areas.empty?
  end

  def update?
    user.has_permission?('stop_area_providers.update')
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
