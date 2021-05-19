module GenericAttributeControl
  module InternalBaseInterface
    extend ActiveSupport::Concern

    included do
      include ComplianceControls::InternalControlInterface
      
      store_accessor :control_attributes, :target

      validates :target, presence: true

      class << self
        def collection_type(compliance_check)
          model_attribute(compliance_check).collection_name
        end

        def lines_for compliance_check, object
          case model_attribute(compliance_check).klass.name
          when 'Chouette::Company' then compliance_check.referential.lines.where(company_id: object.id)
          else
            super
          end
        end

        def label_attr(compliance_check)
          case model_attribute(compliance_check).klass.name
            when 'Chouette::VehicleJourney' then :published_journey_name
            when 'Chouette::Line' then :published_name
            else
              super
          end
        end

        private

        def model_attribute(compliance_check)
          ModelAttribute.find_by_code(compliance_check.target)
        end
      end
    end
  end
end
