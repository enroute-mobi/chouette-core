class ComplianceControl < ActiveRecord::Base

  class << self
    def criticities; %i(warning error) end
    def default_code; "" end
    def dynamic_attributes
      stored_attributes[:control_attributes] || []
    end

    def policy_class
      ComplianceControlPolicy
    end

    def subclass_patterns
      { 
        generic: 'Generic',
        journey_pattern: 'JourneyPattern',
        line: 'Line',
        route: 'Route',
        routing_constraint_zone: 'RoutingConstraint',
        vehicle_journey: 'VehicleJourney'
      }
    end

    def inherited(child)
      child.instance_eval do
        def model_name
          ComplianceControl.model_name
        end
      end
      super
    end
  end

  extend Enumerize
  belongs_to :compliance_control_set
  belongs_to :compliance_control_block

  enumerize :criticity, in: criticities, scope: true, default: :warning

  validates :criticity, presence: true
  validates :name, presence: true
  validates :code, presence: true, uniqueness: { scope: :compliance_control_set }
  validates :origin_code, presence: true
  validates :compliance_control_set, presence: true

  validate def coherent_control_set
  return true if compliance_control_block_id.nil?
  ids = [compliance_control_block.compliance_control_set_id, compliance_control_set_id]
  return true if ids.first == ids.last
  names = ids.map{|id| ComplianceControlSet.find(id).name}
  errors.add(:coherent_control_set,
             I18n.t('compliance_controls.errors.incoherent_control_sets',
                    indirect_set_name: names.first,
                    direct_set_name: names.last))
end


def initialize(attributes = {})
  super
  self.name ||= I18n.t("activerecord.models.#{self.class.name.underscore}.one")
  self.code ||= self.class.default_code
  self.origin_code ||= self.class.default_code
end

def predicate; I18n.t("compliance_controls.#{self.class.name.underscore}.description") end
def prerequisite; I18n.t('compliance_controls.metas.no_prerequisite'); end

end

# Ensure STI subclasses are loaded
# http://guides.rubyonrails.org/autoloading_and_reloading_constants.html#autoloading-and-sti
require_dependency 'generic_attribute_control/min_max'
require_dependency 'generic_attribute_control/pattern'
require_dependency 'generic_attribute_control/uniqueness'
require_dependency 'journey_pattern_control/duplicates'
require_dependency 'journey_pattern_control/vehicle_journey'
require_dependency 'line_control/route'
require_dependency 'route_control/duplicates'
require_dependency 'route_control/journey_pattern'
require_dependency 'route_control/minimum_length'
require_dependency 'route_control/omnibus_journey_pattern'
require_dependency 'route_control/opposite_route_terminus'
require_dependency 'route_control/opposite_route'
require_dependency 'route_control/stop_points_in_journey_pattern'
require_dependency 'route_control/unactivated_stop_point'
require_dependency 'route_control/zdl_stop_area'
require_dependency 'routing_constraint_zone_control/maximum_length'
require_dependency 'routing_constraint_zone_control/minimum_length'
require_dependency 'routing_constraint_zone_control/unactivated_stop_point'
require_dependency 'vehicle_journey_control/delta'
require_dependency 'vehicle_journey_control/waiting_time'
require_dependency 'vehicle_journey_control/speed'
require_dependency 'vehicle_journey_control/time_table'
require_dependency 'vehicle_journey_control/vehicle_journey_at_stops'
