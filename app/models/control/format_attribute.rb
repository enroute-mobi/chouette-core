# frozen_string_literal: true

module Control
  class FormatAttribute < Control::Base
    module Options
      extend ActiveSupport::Concern

      included do # rubocop:disable Metrics/BlockLength
        option :target_model
        option :target_attribute
        option :expected_format

        enumerize :target_model,
                  in: %w[Line StopArea Route JourneyPattern VehicleJourney Company Entrance PointOfInterest Document
                         Shape Network ConnectionLink]
        validates :target_model, :target_attribute, :expected_format, :model_attribute, presence: true

        delegate :table_name, to: :model_attribute

        def model_attribute
          candidate_target_attributes.find_by(model_name: target_model, name: target_attribute)
        end

        def candidate_target_attributes # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
          Chouette::ModelAttribute.collection do # rubocop:disable Metrics/BlockLength
            # Chouette::StopArea
            select Chouette::StopArea, :name
            select Chouette::StopArea, :country_code
            select Chouette::StopArea, :street_name
            select Chouette::StopArea, :zip_code
            select Chouette::StopArea, :city_name
            select Chouette::StopArea, :url
            select Chouette::StopArea, :time_zone
            select Chouette::StopArea, :postal_region
            select Chouette::StopArea, :registration_number
            select Chouette::StopArea, :public_code
            select Chouette::StopArea, :accessibility_limitation_description

            # Chouette::Company
            select Chouette::Company, :name
            select Chouette::Company, :short_name
            select Chouette::Company, :code
            select Chouette::Company, :registration_number
            select Chouette::Company, :time_zone
            select Chouette::Company, :default_language
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

            # Chouette::Line
            select Chouette::Line, :name
            select Chouette::Line, :color
            select Chouette::Line, :number
            select Chouette::Line, :published_name
            select Chouette::Line, :registration_number
            select Chouette::Line, :text_color
            select Chouette::Line, :url
            # Temporary
            select Chouette::Line, :transport_mode
            select Chouette::Line, :transport_submode

            # Chouette::Route
            select Chouette::Route, :name
            select Chouette::Route, :published_name

            # Chouette::JourneyPattern
            select Chouette::JourneyPattern, :name
            select Chouette::JourneyPattern, :published_name

            # Chouette::VehicleJourney
            select Chouette::VehicleJourney, :published_journey_name
            select Chouette::VehicleJourney, :published_journey_identifier
            select Chouette::VehicleJourney, :transport_mode # Temporary

            # Need to check that the Control context provides these models/collections

            # Entrance
            select Entrance, :name
            select Entrance, :short_name
            select Entrance, :address_line_1 # rubocop:disable Naming/VariableNumber
            select Entrance, :zip_code
            select Entrance, :city_name
            select Entrance, :country

            # PointOfInterest
            select PointOfInterest::Base, :name
            select PointOfInterest::Base, :url
            select PointOfInterest::Base, :address_line_1 # rubocop:disable Naming/VariableNumber
            select PointOfInterest::Base, :zip_code
            select PointOfInterest::Base, :city_name
            select PointOfInterest::Base, :country
            select PointOfInterest::Base, :email
            select PointOfInterest::Base, :phone
            select PointOfInterest::Base, :postal_region

            # Document
            select Document, :name

            # Shape
            select Shape, :name

            # Chouette::Network
            select Chouette::Network, :name

            # Chouette::ConnectionLink
            select Chouette::ConnectionLink, :name
          end
        end
      end
    end

    include Options

    class Run < Control::Base::Run
      include Options

      def run
        faulty_models.find_each do |model|
          create_message model
        end
      end

      def create_message(model)
        model_name = model.try(:name) || model.try(:uuid) || model.try(:get_objectid)&.local_id
        attributes = {
          message_attributes: { name: model_name, target_attribute: target_attribute,
                                expected_format: expected_format },
          criticity: criticity,
          source: model
        }
        control_messages.create! attributes
      end

      def faulty_models
        models
          .distinct
          .where
          .not("#{table_name}.#{target_attribute} ~ ?", expected_format)
      end

      def model_collection
        @model_collection ||= target_model.underscore.pluralize.to_sym
      end

      def models
        @models ||= context.send(model_collection)
      end
    end
  end
end
