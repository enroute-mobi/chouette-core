# frozen_string_literal: true

module Chouette
  class ModelAttribute
    attr_reader :model_class, :name, :options

    def self.code(model_class, name)
      "#{model_class.model_name.to_s.underscore}##{name}"
    end

    def self.collection(&block)
      Collection.new(&block)
    end

    # Returns the localized attribute name ("Nom", "Name", "Transporteur", etc)
    def human_name
      # Do not store the value (depend on the current locale)
      I18n.translate! name, scope: ['model_attribute', resource_name]
    rescue I18n::MissingTranslationData
      model_class.human_attribute_name(name)
    end

    def initialize(model_class, name, options = {})
      @model_class = model_class
      @name = name
      @options = options
    end

    # "StopArea", "Line", "Entrance", ...
    def model_name
      @model_name ||= model_class.model_name.to_s
    end

    # :stop_area, :line, :entrance, ...
    def resource_name
      @resource_name ||= model_name.underscore
    end

    # "stop_areas", "lines", "journey_patterns"
    def table_name
      @table_name ||= model_class.reflections["#{name}"]&.klass&.table_name
    end

    # "stop_area#name", "line#name", ...
    def code
      @code ||= "#{resource_name}##{name}"
    end

    def ==(other)
      other && code == other.code
    end

    class Collection
      include Enumerable

      @@model_attributes = []
      cattr_reader :model_attributes
      attr_reader :selected_model_attributes

      def initialize(selected_model_attributes = [], &block)
        @selected_model_attributes = selected_model_attributes
        instance_exec(&block) if block_given?
      end

      def each(&block)
        selected_model_attributes.each(&block)
      end

      def self.define(model_class, name, options = {})
        @@model_attributes << ModelAttribute.new(model_class, name, options)
      end

      def select(model_class, name)
        selected_model_attribute = @@model_attributes.find { |m| m.code == ModelAttribute.code(model_class, name) }
        if selected_model_attribute
          selected_model_attributes << selected_model_attribute
        else
          Rails.logger.error "Selected Model attribute with class #{model_class} and name #{name} doesn't exist in the list"
        end
      end

      def find_by(attributes)
        find do |model_attribute|
          attributes.all? do |k, v|
            model_attribute.send(k).to_s == v.to_s
          end
        end
      end

      # Chouette::Line
      define Chouette::Line, :name
      define Chouette::Line, :active_from
      define Chouette::Line, :active_until
      define Chouette::Line, :color
      define Chouette::Line, :company
      define Chouette::Line, :secondary_companies
      define Chouette::Line, :network
      define Chouette::Line, :number
      define Chouette::Line, :published_name
      define Chouette::Line, :registration_number
      define Chouette::Line, :text_color
      define Chouette::Line, :transport_mode
      define Chouette::Line, :transport_submode
      define Chouette::Line, :url

      # Chouette::Network
      define Chouette::Network, :name

      # Chouette::Company
      define Chouette::Company, :name
      define Chouette::Company, :short_name
      define Chouette::Company, :code
      define Chouette::Company, :customer_service_contact_email
      define Chouette::Company, :customer_service_contact_more
      define Chouette::Company, :customer_service_contact_name
      define Chouette::Company, :customer_service_contact_phone
      define Chouette::Company, :customer_service_contact_url
      define Chouette::Company, :default_contact_email
      define Chouette::Company, :default_contact_fax
      define Chouette::Company, :default_contact_more
      define Chouette::Company, :default_contact_name
      define Chouette::Company, :default_contact_operating_department_name
      define Chouette::Company, :default_contact_organizational_unit
      define Chouette::Company, :default_contact_phone
      define Chouette::Company, :default_contact_url
      define Chouette::Company, :default_language
      define Chouette::Company, :private_contact_email
      define Chouette::Company, :private_contact_more
      define Chouette::Company, :private_contact_name
      define Chouette::Company, :private_contact_phone
      define Chouette::Company, :private_contact_url
      define Chouette::Company, :address_line_1
      define Chouette::Company, :address_line_2
      define Chouette::Company, :country_code
      define Chouette::Company, :house_number
      define Chouette::Company, :postcode
      define Chouette::Company, :postcode_extension
      define Chouette::Company, :registration_number
      define Chouette::Company, :street
      define Chouette::Company, :time_zone
      define Chouette::Company, :town

      # Chouette::StopArea
      define Chouette::StopArea, :name
      define Chouette::StopArea, :parent
      define Chouette::StopArea, :referent
      define Chouette::StopArea, :fare_code
      define Chouette::StopArea, :coordinates
      define Chouette::StopArea, :country_code
      define Chouette::StopArea, :street_name
      define Chouette::StopArea, :zip_code
      define Chouette::StopArea, :city_name
      define Chouette::StopArea, :url
      define Chouette::StopArea, :time_zone
      define Chouette::StopArea, :waiting_time
      define Chouette::StopArea, :postal_region
      define Chouette::StopArea, :public_code
      define Chouette::StopArea, :registration_number
      define Chouette::StopArea, :compass_bearing, data_type: :float
      define Chouette::StopArea, :accessibility_limitation_description
      define Chouette::StopArea, :escalator_free_accessibility
      define Chouette::StopArea, :lift_free_accessibility
      define Chouette::StopArea, :mobility_impaired_accessibility
      define Chouette::StopArea, :step_free_accessibility
      define Chouette::StopArea, :wheelchair_accessibility
      define Chouette::StopArea, :visual_signs_availability
      define Chouette::StopArea, :lines
      define Chouette::StopArea, :routes

      # Chouette::Route
      define Chouette::Route, :name
      define Chouette::Route, :published_name
      define Chouette::Route, :opposite_route
      define Chouette::Route, :journey_patterns
      define Chouette::Route, :vehicle_journeys
      define Chouette::Route, :stop_points
      define Chouette::Route, :wayback

      # Chouette::JourneyPattern
      define Chouette::JourneyPattern, :name
      define Chouette::JourneyPattern, :published_name
      define Chouette::JourneyPattern, :stop_points
      define Chouette::JourneyPattern, :vehicle_journeys
      define Chouette::JourneyPattern, :shape

      # Chouette::VehicleJourney
      define Chouette::VehicleJourney, :published_journey_name
      define Chouette::VehicleJourney, :company
      define Chouette::VehicleJourney, :transport_mode
      define Chouette::VehicleJourney, :published_journey_identifier
      define Chouette::VehicleJourney, :time_tables
      define Chouette::VehicleJourney, :transport_mode

      # Chouette::TimeTable
      define Chouette::TimeTable, :dates
      define Chouette::TimeTable, :periods

      # Chouette::Footnote
      define Chouette::Footnote, :code
      define Chouette::Footnote, :label

      # Chouette::RoutingConstraintZone
      define Chouette::RoutingConstraintZone, :name

      # Chouette::ConnectionLink
      define Chouette::ConnectionLink, :name

      # Document
      define Document, :name

      # Entrance
      define Entrance, :address_line_1 # rubocop:disable Naming/VariableNumber
      define Entrance, :city_name
      define Entrance, :country
      define Entrance, :name
      define Entrance, :short_name
      define Entrance, :zip_code

      # PointOfInterest::Base
      define PointOfInterest::Base, :address_line_1 # rubocop:disable Naming/VariableNumber
      define PointOfInterest::Base, :city_name
      define PointOfInterest::Base, :country
      define PointOfInterest::Base, :email
      define PointOfInterest::Base, :name
      define PointOfInterest::Base, :phone
      define PointOfInterest::Base, :postal_region
      define PointOfInterest::Base, :url
      define PointOfInterest::Base, :zip_code

      # Shape
      define Shape, :name

    end
  end
end
