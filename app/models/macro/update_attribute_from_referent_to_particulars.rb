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
        enumerize :override_existing_value, in: %w[true false]

        validates :target_model, :target_attribute, presence: true
      end

      def model_attribute
        candidate_target_attributes.find_by(model_name: target_model, name: target_attribute)
      end

      def candidate_target_attributes # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
        Chouette::ModelAttribute.collection do # rubocop:disable Metrics/BlockLength
          select Chouette::StopArea, :name
          select Chouette::StopArea, :parent
          select Chouette::StopArea, :country_code
          select Chouette::StopArea, :street_name
          select Chouette::StopArea, :zip_code
          select Chouette::StopArea, :city_name
          select Chouette::StopArea, :postal_region
          select Chouette::StopArea, :public_code
          # select Chouette::StopArea, :registration_number
          select Chouette::StopArea, :time_zone
          select Chouette::StopArea, :waiting_time
          select Chouette::StopArea, :url
          select Chouette::StopArea, :mobility_impaired_accessibility
          select Chouette::StopArea, :wheelchair_accessibility
          select Chouette::StopArea, :step_free_accessibility
          select Chouette::StopArea, :escalator_free_accessibility
          select Chouette::StopArea, :lift_free_accessibility
          select Chouette::StopArea, :audible_signals_availability
          select Chouette::StopArea, :visual_signs_availability
          select Chouette::StopArea, :accessibility_limitation_description

          select Chouette::Company, :short_name
          select Chouette::Company, :code
          # select Chouette::Company, :registration_number
          select Chouette::Company, :time_zone
          select Chouette::Company, :house_number
          select Chouette::Company, :address_line_1 # rubocop:disable Naming/VariableNumber
          select Chouette::Company, :address_line_2 # rubocop:disable Naming/VariableNumber
          select Chouette::Company, :street
          select Chouette::Company, :postcode
          select Chouette::Company, :postcode_extension
          select Chouette::Company, :town
          select Chouette::Company, :country_code
          select Chouette::Company, :default_contact_name
          select Chouette::Company, :default_contact_email
          select Chouette::Company, :default_contact_phone
          select Chouette::Company, :default_contact_url
          select Chouette::Company, :default_contact_more
          select Chouette::Company, :customer_service_contact_name
          select Chouette::Company, :customer_service_contact_email
          select Chouette::Company, :customer_service_contact_phone
          select Chouette::Company, :customer_service_contact_url
          select Chouette::Company, :customer_service_contact_more
          select Chouette::Company, :private_contact_name
          select Chouette::Company, :private_contact_email
          select Chouette::Company, :private_contact_phone
          select Chouette::Company, :private_contact_url
          select Chouette::Company, :private_contact_more
          select Chouette::Company, :default_language
        end
      end

      def override_existing_value?
        override_existing_value.in?([true, 'true'])
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        models.includes(:referent).find_each do |particular|
          value = particular.referent.send(attribute_name)
          previous_attribute_value = particular.send attribute_name

          particular.update attribute_name => value
          create_message particular, attribute_name, value, previous_attribute_value
        end
      end

      def create_message(particular, attribute_name, attribute_value, previous_attribute_value)
        # When value is an enumerize value
        attribute_value = attribute_value.text if attribute_value.respond_to?(:text)

        name = particular.name
        name = previous_attribute_value if attribute_name == :name

        attributes = {
          message_attributes: {
            name: name,
            target_attribute: attribute_name,
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

      def models
        @models ||= begin
          scope_models = scope.send(model_collection).particulars.with_referent
          scope_models = scope_models.where(attribute_name => undefined_value) unless override_existing_value?
          scope_models
        end
      end

      def undefined_value
        # For example Chouette::StopArea.wheelchair_accessibility.default_value => "unknown"
        # or nil ...
        model_attribute.model_class.try(attribute_name).try(:default_value)
      end
    end
  end
end
