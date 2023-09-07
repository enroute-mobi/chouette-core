module Control
  class PresenceAttribute < Control::Base

    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :target_attribute

        enumerize :target_model, in: %w{Line StopArea JourneyPattern VehicleJourney Company}

        validates :target_model, :target_attribute, :model_attribute, presence: true

        delegate :collection_name, to: :model_attribute

        def model_attribute
          candidate_target_attributes.find_by(model_name: target_model, name: target_attribute)
        end

        def candidate_target_attributes # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
          Chouette::ModelAttribute.empty do # rubocop:disable Metrics/BlockLength
            # Chouette::StopArea
            define Chouette::StopArea, :name
            define Chouette::StopArea, :country_code
            define Chouette::StopArea, :street_name
            define Chouette::StopArea, :zip_code
            define Chouette::StopArea, :city_name
            define Chouette::StopArea, :url
            define Chouette::StopArea, :time_zone
            define Chouette::StopArea, :postal_region
            define Chouette::StopArea, :registration_number
            define Chouette::StopArea, :public_code
            define Chouette::StopArea, :accessibility_limitation_description

            # Chouette::Company
            define Chouette::Company, :name
            define Chouette::Company, :short_name
            define Chouette::Company, :code
            define Chouette::Company, :registration_number
            define Chouette::Company, :time_zone
            define Chouette::Company, :default_language
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

            # Chouette::Line
            define Chouette::Line, :name
            define Chouette::Line, :color
            define Chouette::Line, :number
            define Chouette::Line, :published_name
            define Chouette::Line, :registration_number
            define Chouette::Line, :text_color
            define Chouette::Line, :url
            # Temporary
            define Chouette::Line, :transport_mode
            define Chouette::Line, :transport_submode

            # Chouette::Route
            define Chouette::Route, :name
            define Chouette::Route, :published_name

            # Chouette::JourneyPattern
            define Chouette::JourneyPattern, :name
            define Chouette::JourneyPattern, :published_name

            # Chouette::VehicleJourney
            define Chouette::VehicleJourney, :published_journey_name
            define Chouette::VehicleJourney, :published_journey_identifier
            define Chouette::VehicleJourney, :transport_mode # Temporary

            # Need to check that the Control context provides these models/collections

            define Entrance, :name
            define Entrance, :short_name
            define Entrance, :address_line_1 # rubocop:disable Naming/VariableNumber
            define Entrance, :zip_code
            define Entrance, :city_name
            define Entrance, :country

            define PointOfInterest::Base, :name
            define PointOfInterest::Base, :url
            define PointOfInterest::Base, :address_line_1 # rubocop:disable Naming/VariableNumber
            define PointOfInterest::Base, :zip_code
            define PointOfInterest::Base, :city_name
            define PointOfInterest::Base, :country
            define PointOfInterest::Base, :email
            define PointOfInterest::Base, :phone
            define PointOfInterest::Base, :postal_region

            define Document, :name
            define Shape, :name

            define Chouette::Network, :name
            define Chouette::ConnectionLink, :name
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
            message_attributes: { name: (model.name rescue model.id) },
            criticity: criticity,
            source: model,
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
          with_query = WithQuery.create(scope, model_attribute)
          return with_query if with_query

          if model_attribute.options[:reference]
            Reference.new scope, model_attribute
          else
            SimpleAttribute.new scope, model_attribute
          end
        end
      end

      class SimpleAttribute < Finder
        def faulty_models
          scope.where(model_attribute.name => nil)
        end
      end

      class Reference < Finder
        def faulty_models
          scope.left_joins(model_attribute.name).where(association_collection => { id: nil })
        end

        def association_collection
          model_attribute.options[:association_collection] ||
          model_attribute.name.to_s.pluralize.to_sym
        end
      end

      class WithQuery < Finder
        def self.create(scope, model_attribute)
          with_query = new(scope, model_attribute)
          with_query if with_query.support?
        end

        def support?
          query.respond_to? query_method
        end

        def query_class
          Query.for model_attribute.klass rescue nil
        end

        def query
          @query ||= query_class.new scope if query_class
        end

        def query_method
          "without_#{model_attribute.name}"
        end

        def faulty_models
          query.send query_method
        end
      end

      def model_attribute
        @model_attribute ||= ::ModelAttribute.find_by_code(model_attribute_code)
      end

      def model_attribute_code
        @model_attribute_code ||= "#{target_model.underscore}##{target_attribute}"
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
