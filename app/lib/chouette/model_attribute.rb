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
    def collection_name
      @collection_name ||= resource_name.pluralize
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
      define Chouette::Line, :company, { reference: true, association_collection: :companies }
      define Chouette::Line, :network, { reference: true, association_collection: :networks }
      define Chouette::Line, :number
      define Chouette::Line, :published_name
      define Chouette::Line, :registration_number
      define Chouette::Line, :text_color
      define Chouette::Line, :transport_mode
      define Chouette::Line, :transport_submode
      define Chouette::Line, :url

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
      define Chouette::StopArea, :parent, { reference: true }
      define Chouette::StopArea, :referent, { reference: true }
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

      # Chouette::Route
      define Chouette::Route, :name
      define Chouette::Route, :published_name
      define Chouette::Route, :opposite_route, { reference: true }
      define Chouette::Route, :wayback

      # Chouette::JourneyPattern
      define Chouette::JourneyPattern, :name
      define Chouette::JourneyPattern, :published_name
      define Chouette::JourneyPattern, :shape, { reference: true, association_collection: :shapes }

      # Chouette::VehicleJourney
      define Chouette::VehicleJourney, :published_journey_name
      define Chouette::VehicleJourney, :company, { reference: true, association_collection: :companies }
      define Chouette::VehicleJourney, :transport_mode
      define Chouette::VehicleJourney, :published_journey_identifier

      # Chouette::Footnote
      define Chouette::Footnote, :code
      define Chouette::Footnote, :label

      # Chouette::RoutingConstraintZone
      define Chouette::RoutingConstraintZone, :name
    end
  end
end
