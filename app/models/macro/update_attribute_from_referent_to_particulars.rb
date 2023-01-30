# frozen_string_literal: true
module Macro
  class UpdateAttributeFromReferentToParticulars < Macro::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :target_attribute
        option :override_existing_value

        enumerize :target_model, in: %w[StopArea Company]
        enumerize :override_existing_value, in: [ true, false ]

        validates :target_model, :target_attribute, :override_existing_value, presence: true
      end

      def model_attribute
        candidate_target_attributes.find_by(model_name: target_model, name: target_attribute)
      end

      def candidate_target_attributes # rubocop:disable Metrics/MethodLength
        Chouette::ModelAttribute.empty do
          define Chouette::StopArea, :parent
          define Chouette::StopArea, :fare_code
          define Chouette::StopArea, :country_code
          define Chouette::StopArea, :street_name
          define Chouette::StopArea, :zip_code
          define Chouette::StopArea, :city_name
          define Chouette::StopArea, :postal_region
          define Chouette::StopArea, :public_code
          define Chouette::StopArea, :registration_number
          define Chouette::StopArea, :time_zone
          define Chouette::StopArea, :waiting_time
          define Chouette::StopArea, :url
          define Chouette::StopArea, :mobility_impaired_accessibility
          define Chouette::StopArea, :wheelchair_accessibility
          define Chouette::StopArea, :step_free_accessibility
          define Chouette::StopArea, :escalator_free_accessibility
          define Chouette::StopArea, :lift_free_accessibility
          define Chouette::StopArea, :audible_signals_availability
          define Chouette::StopArea, :visual_signs_availability
          define Chouette::StopArea, :accessibility_limitation_description

          define Chouette::Company, :short_name
          define Chouette::Company, :code
          define Chouette::Company, :registration_number
          define Chouette::Company, :time_zone
          define Chouette::Company, :house_number
          define Chouette::Company, :address_line_1 # rubocop:disable Naming/VariableNumber
          define Chouette::Company, :address_line_2 # rubocop:disable Naming/VariableNumber
          define Chouette::Company, :street
          define Chouette::Company, :postcode
          define Chouette::Company, :postcode_extension
          define Chouette::Company, :town
          define Chouette::Company, :country_code
          define Chouette::Company, :default_contact_name
          define Chouette::Company, :default_contact_email
          define Chouette::Company, :default_contact_phone
          define Chouette::Company, :default_contact_url
          define Chouette::Company, :default_contact_more
          define Chouette::Company, :customer_service_contact_name
          define Chouette::Company, :customer_service_contact_email
          define Chouette::Company, :customer_service_contact_phone
          define Chouette::Company, :customer_service_contact_url
          define Chouette::Company, :customer_service_contact_more
          define Chouette::Company, :private_contact_name
          define Chouette::Company, :private_contact_email
          define Chouette::Company, :private_contact_phone
          define Chouette::Company, :private_contact_url
          define Chouette::Company, :private_contact_more
        end
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        referents.includes(:particulars).find_each do |referent|
          value = referent.send(attribute_name)

          referent.particulars.find_each do |particular|

            particular.update(attribute_name => value)
            create_message(particular, attribute_name, value)
          end
        end
      end

      def create_message(particular, attribute_name, attribute_value = nil)
        attributes = {
          message_attributes: {
            name: particular.name, attribute_name:
            particular.class.human_attribute_name(attribute_name),
            attribute_value: attribute_value
          },
          source: particular
        }

        attributes.merge!(criticity: 'error', message_key: 'error') unless particular.valid?

        macro_messages.create!(attributes)
      end

      def model_collection
        @model_collection ||= model_attribute.model_class.model_name.plural
      end

      def attribute_name
        model_attribute.name
      end

      def referents
        @referents ||= models.referents
      end

      def models
        @models ||= scope.send(model_collection)
      end
    end
  end
end