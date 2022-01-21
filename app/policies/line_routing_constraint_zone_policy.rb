class LineRoutingConstraintZonePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def create?
    instance_permission(:create)
  end

  def destroy?
    instance_permission(:destroy)
  end

  def update?
    instance_permission(:update)
  end

  def instance_permission permission
    user.has_permission?("line_routing_constraint_zones.#{permission}")
  end
end
