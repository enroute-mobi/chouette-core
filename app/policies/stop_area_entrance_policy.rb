class StopAreaEntrancePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    instance_permission(:create)
  end

  def destroy?
    instance_permission(:destroy) && stop_area_provider_matches?
  end

  def update?
    instance_permission(:update) && stop_area_provider_matches?
  end

  def instance_permission permission
    user.has_permission?("stop_area_entrances.#{permission}")
  end
end
