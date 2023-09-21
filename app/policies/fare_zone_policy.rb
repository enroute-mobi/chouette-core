class FareZonePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    user.has_permission?('fare_zones.create')
  end

  def update?
    user.has_permission?('fare_zones.update')
  end

  def destroy?
    user.has_permission?('fare_zones.destroy')
  end

end
