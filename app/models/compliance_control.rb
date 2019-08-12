class ComplianceControl < ApplicationModel
  include ComplianceItemSupport

  class << self
    def criticities; %i(warning error) end
    def default_code; "" end

    def policy_class
      ComplianceControlPolicy
    end

    def block_class
      self.parent.to_s.sub('Control', '').underscore
    end

    def iev_enabled_check
      true
    end

    def available_for_organisation? organisation
      out = @required_features.present? ? ((organisation.features.map(&:to_sym) & @required_features.map(&:to_sym)).size == @required_features.map(&:to_sym).size) : true
      out && (@constraints || []).all?{|test| !!test.call(organisation) }
    end

    def required_features *features
      @required_features ||= []
      @required_features += features
    end

    def only_if test
      @constraints ||= []
      @constraints << test
    end

    def only_with_custom_field klass, field_code
      only_if ->(organisation) { organisation.workgroups.any?{|workgroup| klass.custom_fields(workgroup).where(code: field_code).exists? }}
    end

    def subclass_patterns
      {
        generic: 'Generic',
        journey_pattern: 'JourneyPattern',
        line: 'Line',
        route: 'Route',
        routing_constraint_zone: 'RoutingConstraint',
        vehicle_journey: 'VehicleJourney',
        dummy: 'Dummy',
        company: 'Company',
        stop_area: 'StopArea',
      }
    end

    def subclasses_to_hash organisation=nil
      if self.subclasses.empty?
        if organisation.nil? || self.available_for_organisation?(organisation)
          return {ComplianceControl.subclass_patterns.key(self.object_type) => [self]}
        else
          return {}
        end
      else
        out = {}
        self.subclasses.each do |k|
          sub_hash = k.subclasses_to_hash organisation
          sub_hash.each do |k, v|
            out[k] ||= []
            out[k] += v
          end
        end
        return out
      end
    end

    def translated_subclass
      I18n.t("compliance_controls.filters.subclasses.#{subclass_patterns.key(self.object_type)}")
    end

    def object_type
      self.default_code.match(/^\d+-(?'object_type'\w+)-\d+$/)[:object_type]
    end

    def inherited(child)
      child.instance_eval do
        def model_name
          ComplianceControl.model_name
        end
      end
      super
    end

    def predicate; I18n.t("compliance_controls.#{self.name.underscore}.description") end
    def prerequisite; I18n.t("compliance_controls.#{self.name.underscore}.prerequisite") end

    def import(data, control_set:, control_block: nil)
      create!({compliance_control_set_id: control_set.id, compliance_control_block_id: control_block&.id}.update(data))
    end
  end

  extend Enumerize
  belongs_to :compliance_control_set
  belongs_to :compliance_control_block
  has_one :organisation, through: :compliance_control_set

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

  def predicate; self.class.predicate end
  def prerequisite; self.class.prerequisite end

  def export
    attributes.symbolize_keys.slice(:name, :code, :type, :control_attributes, :criticity, :comment, :origin_code, :iev_enabled_check)
  end
end

# Ensure STI subclasses are loaded
# http://guides.rubyonrails.org/autoloading_and_reloading_constants.html#autoloading-and-sti
require_dependency 'compliance_controls/company_control/name_is_present'
require_dependency 'compliance_controls/dummy_control/dummy' if InternalControl::Base.enabled?("dummy")
require_dependency 'compliance_controls/stop_area_control/time_zone'
require_dependency 'compliance_controls/generic_attribute_control/min_max'
require_dependency 'compliance_controls/generic_attribute_control/pattern'
require_dependency 'compliance_controls/generic_attribute_control/uniqueness'
require_dependency 'compliance_controls/journey_pattern_control/duplicates'
require_dependency 'compliance_controls/journey_pattern_control/minimum_length'
require_dependency 'compliance_controls/journey_pattern_control/vehicle_journey'
require_dependency 'compliance_controls/journey_pattern_control/min_max_distance_cost'
require_dependency 'compliance_controls/journey_pattern_control/min_max_time_cost'
require_dependency 'compliance_controls/line_control/active'
require_dependency 'compliance_controls/line_control/lines_scope'
require_dependency 'compliance_controls/line_control/route'
require_dependency 'compliance_controls/route_control/border_count'
require_dependency 'compliance_controls/route_control/duplicates'
require_dependency 'compliance_controls/route_control/journey_pattern'
require_dependency 'compliance_controls/route_control/minimum_length'
require_dependency 'compliance_controls/route_control/omnibus_journey_pattern'
require_dependency 'compliance_controls/route_control/opposite_route_terminus'
require_dependency 'compliance_controls/route_control/opposite_route'
require_dependency 'compliance_controls/route_control/stop_points_boarding_and_alighting'
require_dependency 'compliance_controls/route_control/stop_points_in_journey_pattern'
require_dependency 'compliance_controls/route_control/unactivated_stop_point'
require_dependency 'compliance_controls/route_control/valid_stop_areas'
require_dependency 'compliance_controls/route_control/zdl_stop_area'
require_dependency 'compliance_controls/routing_constraint_zone_control/maximum_length'
require_dependency 'compliance_controls/routing_constraint_zone_control/minimum_length'
require_dependency 'compliance_controls/routing_constraint_zone_control/unactivated_stop_point'
require_dependency 'compliance_controls/vehicle_journey_control/bus_capacity'
require_dependency 'compliance_controls/vehicle_journey_control/delta'
require_dependency 'compliance_controls/vehicle_journey_control/published_journey_name'
require_dependency 'compliance_controls/vehicle_journey_control/purchase_window_dates'
require_dependency 'compliance_controls/vehicle_journey_control/purchase_window'
require_dependency 'compliance_controls/vehicle_journey_control/speed'
require_dependency 'compliance_controls/vehicle_journey_control/time_table'
require_dependency 'compliance_controls/vehicle_journey_control/vehicle_journey_at_stops'
require_dependency 'compliance_controls/vehicle_journey_control/bus_capacity'
require_dependency 'compliance_controls/vehicle_journey_control/purchase_window'
require_dependency 'compliance_controls/vehicle_journey_control/purchase_window_dates'
require_dependency 'compliance_controls/vehicle_journey_control/published_journey_name'
require_dependency 'compliance_controls/vehicle_journey_control/waiting_time'
require_dependency 'compliance_controls/company_control/name_is_present'
require_dependency 'compliance_controls/vehicle_journey_control/empty_time_table'
require_dependency 'compliance_controls/custom_field_control/presence'
