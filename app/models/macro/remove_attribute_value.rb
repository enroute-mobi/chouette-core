# frozen_string_literal: true

module Macro
  class RemoveAttributeValue < Macro::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :target_attribute

        enumerize :target_model, in: %w[
          StopArea
          Company
          Line
          Entrance
          PointOfInterest
          Footnote
          VehicleJourney
          JourneyPattern
          Route
        ]

        validates :target_model, :target_attribute, :model_attribute, presence: true
      end

      def model_attribute
        candidate_target_attributes.find_by(model_name: target_model, name: target_attribute)
      end

      def candidate_target_attributes
        Chouette::ModelAttribute.collection do
          # Chouette::Line
          select Chouette::Line, :active_from
          select Chouette::Line, :active_until
          select Chouette::Line, :color
          select Chouette::Line, :company
          select Chouette::Line, :secondary_companies
          select Chouette::Line, :network
          select Chouette::Line, :number
          select Chouette::Line, :published_name
          select Chouette::Line, :registration_number
          select Chouette::Line, :text_color
          select Chouette::Line, :transport_mode
          select Chouette::Line, :url
          select Chouette::Line, :referent_id

          # Chouette::Company
          select Chouette::Company, :short_name
          select Chouette::Company, :code
          select Chouette::Company, :customer_service_contact_email
          select Chouette::Company, :customer_service_contact_more
          select Chouette::Company, :customer_service_contact_name
          select Chouette::Company, :customer_service_contact_phone
          select Chouette::Company, :customer_service_contact_url
          select Chouette::Company, :default_contact_email
          select Chouette::Company, :default_contact_fax
          select Chouette::Company, :default_contact_more
          select Chouette::Company, :default_contact_name
          select Chouette::Company, :default_contact_operating_department_name
          select Chouette::Company, :default_contact_organizational_unit
          select Chouette::Company, :default_contact_phone
          select Chouette::Company, :default_contact_url
          select Chouette::Company, :default_language
          select Chouette::Company, :private_contact_email
          select Chouette::Company, :private_contact_more
          select Chouette::Company, :private_contact_name
          select Chouette::Company, :private_contact_phone
          select Chouette::Company, :private_contact_url
          select Chouette::Company, :address_line_1
          select Chouette::Company, :address_line_2
          select Chouette::Company, :country_code
          select Chouette::Company, :house_number
          select Chouette::Company, :postcode
          select Chouette::Company, :postcode_extension
          select Chouette::Company, :registration_number
          select Chouette::Company, :street
          select Chouette::Company, :time_zone
          select Chouette::Company, :town
          select Chouette::Company, :referent_id
          # select Chouette::Company, :is_referent

          # Chouette::StopArea
          select Chouette::StopArea, :parent
          select Chouette::StopArea, :referent
          select Chouette::StopArea, :coordinates
          select Chouette::StopArea, :country_code
          select Chouette::StopArea, :street_name
          select Chouette::StopArea, :zip_code
          select Chouette::StopArea, :city_name
          select Chouette::StopArea, :url
          select Chouette::StopArea, :time_zone
          select Chouette::StopArea, :waiting_time
          select Chouette::StopArea, :postal_region
          select Chouette::StopArea, :public_code
          select Chouette::StopArea, :transport_mode
          select Chouette::StopArea, :registration_number
          select Chouette::StopArea, :compass_bearing
          select Chouette::StopArea, :accessibility_limitation_description
          select Chouette::StopArea, :escalator_free_accessibility
          select Chouette::StopArea, :lift_free_accessibility
          select Chouette::StopArea, :mobility_impaired_accessibility
          select Chouette::StopArea, :step_free_accessibility
          select Chouette::StopArea, :wheelchair_accessibility
          select Chouette::StopArea, :audible_signals_availability
          select Chouette::StopArea, :visual_signs_availability
          # select Chouette::StopArea, :lines
          # select Chouette::StopArea, :routes
          # select Chouette::StopArea, :fare_zones

          # Chouette::Route
          select Chouette::Route, :published_name
          select Chouette::Route, :opposite_route

          # Chouette::JourneyPattern
          select Chouette::JourneyPattern, :published_name
          select Chouette::JourneyPattern, :shape

          # Chouette::VehicleJourney
          select Chouette::VehicleJourney, :published_journey_name
          select Chouette::VehicleJourney, :company
          select Chouette::VehicleJourney, :transport_mode
          select Chouette::VehicleJourney, :published_journey_identifier
          # select Chouette::VehicleJourney, :time_tables

          # Chouette::Footnote
          select Chouette::Footnote, :code
          select Chouette::Footnote, :label

          # Entrance
          select Entrance, :short_name
          select Entrance, :address_line_1
          select Entrance, :zip_code
          select Entrance, :city_name
          select Entrance, :country

          # PointOfInterest::Base
          select PointOfInterest::Base, :url
          select PointOfInterest::Base, :address_line_1 # rubocop:disable Naming/VariableNumber
          select PointOfInterest::Base, :zip_code
          select PointOfInterest::Base, :city_name
          select PointOfInterest::Base, :country
          select PointOfInterest::Base, :email
          select PointOfInterest::Base, :phone
          select PointOfInterest::Base, :postal_region
        end
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        candidate_models.in_batches(of: 10000) do |batch|
          updated_models = batch.to_a

          if batch.update_all(updated_attributes.merge(updated_at: Time.zone.now)).positive?
            updated_models.each { |model| messages.create(source: model) }
          end
        end
      end

      def candidate_models
        models.where.not(updated_attributes)
      end

      def updated_attributes
        case [target_model, target_attribute]
        when ['Line', 'transport_mode']
          { transport_mode: nil, transport_submode: 'undefined' }
        when ['Line', 'secondary_companies']
          { secondary_company_ids: nil }
        when ['StopArea', 'coordinates']
          { latitude: nil, longitude: nil }
        else
          { target_attribute => default_attribute_value }
        end
      end

      def default_attribute_value
        return @default_attribute_value if defined?(@default_attribute_value)

        @default_attribute_value ||= models.column_for_attribute(target_attribute).default
      end

      def model_collection
        @model_collection ||= model_attribute.model_class.model_name.plural
      end

      def models
        @models ||= scope.send(model_collection)
      end
    end
  end
end
