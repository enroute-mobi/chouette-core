module RoutingConstraintZoneControl
  class InternalBase < InternalControl::Base
    def self.object_path(compliance_check, rcz)
       referential_line_routing_constraint_zone_path(
        rcz.referential,
        rcz.line,
        rcz
      )
    end

    def self.collection_type(_)
      :routing_constraint_zones
    end
  end
end
