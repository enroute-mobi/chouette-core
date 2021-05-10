module GenericAttributeControl
  class InternalBase < InternalControl::Base
    store_accessor :control_attributes, :target

    validates :target, presence: true

    class << self
      def object_path(compliance_check, object)
        name = object.model_name.name
        klass = "#{name}Control::InternalBase".constantize

        klass.object_path(compliance_check, object)
      rescue NameError => e
        raise 'Could not find control class', e
      end

      def collection_type(compliance_check)
        resource_name(compliance_check)
          .pluralize
          .to_sym
      end

      private

      def resource_name compliance_check
        compliance_check
          .target
          .split('#')
          .first
      end

      def attribute_name compliance_check
        compliance_check
          .target
          .split('#')
          .last
      end
    end
  end
end

require_dependency 'compliance_controls/company_control/internal_base'
require_dependency 'compliance_controls/footnote_control/internal_base'
require_dependency 'compliance_controls/journey_pattern_control/internal_base'
require_dependency 'compliance_controls/line_control/internal_base'
require_dependency 'compliance_controls/route_control/internal_base'
require_dependency 'compliance_controls/routing_constraint_zone_control/internal_base'
require_dependency 'compliance_controls/stop_area_control/internal_base'
require_dependency 'compliance_controls/vehicle_journey_control/internal_base'
