# frozen_string_literal: true

module Control
  class AbsenceAttribute < Control::Base

    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :target_attribute

        enumerize :target_model, in: %w[
          Line
          StopArea
          Entrance
          PointOfInterest
          Route
          JourneyPattern
          VehicleJourney
          Shape
          Company
          Document
          Network
          ConnectionLink
        ]

        validates :target_model, :target_attribute, :model_attribute, presence: true

        delegate :collection_name, to: :model_attribute

        def model_attribute
          candidate_target_attributes.find_by(model_name: target_model, name: target_attribute)
        end

        def candidate_target_attributes
          Chouette::ModelAttribute.collection do
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
            select Chouette::StopArea, :compass_bearing
            select Chouette::StopArea, :coordinates
            select Chouette::StopArea, :waiting_time
            select Chouette::StopArea, :referent
            select Chouette::StopArea, :parent

            # Chouette::Company
            select Chouette::Company, :name
            select Chouette::Company, :short_name
            select Chouette::Company, :code
            select Chouette::Company, :registration_number
            select Chouette::Company, :time_zone
            select Chouette::Company, :default_language
            select Chouette::Company, :house_number
            select Chouette::Company, :address_line_1
            select Chouette::Company, :address_line_2
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
            select Chouette::Line, :referent_id
            select Chouette::Line, :transport_mode
            select Chouette::Line, :transport_submode

            # Chouette::Route
            select Chouette::Route, :name
            select Chouette::Route, :published_name
            select Chouette::Route, :wayback

            # Chouette::JourneyPattern
            select Chouette::JourneyPattern, :name
            select Chouette::JourneyPattern, :published_name

            # Chouette::VehicleJourney
            select Chouette::VehicleJourney, :published_journey_name
            select Chouette::VehicleJourney, :published_journey_identifier
            select Chouette::VehicleJourney, :transport_mode

            select Entrance, :name
            select Entrance, :short_name
            select Entrance, :address_line_1
            select Entrance, :zip_code
            select Entrance, :city_name
            select Entrance, :country

            select PointOfInterest::Base, :name
            select PointOfInterest::Base, :url
            select PointOfInterest::Base, :address_line_1
            select PointOfInterest::Base, :zip_code
            select PointOfInterest::Base, :city_name
            select PointOfInterest::Base, :country
            select PointOfInterest::Base, :email
            select PointOfInterest::Base, :phone
            select PointOfInterest::Base, :postal_region

            select Document, :name
            select Shape, :name

            select Chouette::Network, :name
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
          control_messages.create!({
            message_attributes: { name: (model.name rescue model.id), target_attribute: target_attribute },
            criticity: criticity,
            source: model,
            message_key: :absence_attribute
          })
        end
      end

      def faulty_models
        finder.faulty_models
      end

      def finder
        Finder.create models, model_attribute
      end

      class Finder
        attr_accessor :scope, :model_attribute

        def initialize(scope, model_attribute)
          @scope = scope
          @model_attribute = model_attribute
        end

        def self.create(scope, model_attribute)
          with_query = WithQuery.new(scope, model_attribute)
          return with_query if with_query.support?

          if model_attribute.model_class.reflections[model_attribute.name]
            Reference.new scope, model_attribute
          else
            SimpleAttribute.new scope, model_attribute
          end
        end

        def default_value
          @default_value ||= model_class.column_defaults[filed_name]
        end

        def model_class
          @model_class ||= model_attribute.model_class
        end

        def filed_name
          @filed_name ||= model_attribute.name.to_s
        end
      end

      class SimpleAttribute < Finder
        def faulty_models
          scope.where.not(filed_name => default_value)
        end
      end

      class Reference < Finder
        def faulty_models
          scope.left_joins(filed_name).where.not(association_collection => { id: nil })
        end

        def association_collection
          model_attribute.options[:association_collection] || filed_name.pluralize.to_sym
        end
      end

      class WithQuery < Finder

        def support?
          query.respond_to? query_method
        end

        def query_class
          ::Query.for model_class rescue nil
        end

        def query
          @query ||= query_class.new scope if query_class
        end

        def query_method
          "with_#{filed_name}"
        end

        def faulty_models
          query.send query_method
        end
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
