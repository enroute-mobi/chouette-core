# frozen_string_literal: true

module Chouette
  class ModelAttribute
    attr_reader :model_class, :name

    # "StopArea", "Line", "Entrance", ...
    def model_name
      @model_name ||= model_class.model_name.to_s
    end

    # :stop_area, :line, :entrance, ...
    def resource_name
      @resource_name ||= model_name.underscore.to_sym
    end

    # "stop_areas", "lines", "journey_patterns"
    def collection_name
      @collection_name ||= model_name.underscore.pluralize
    end

    # "stop_area#name", "line#name", ...
    def code
      @code ||= "#{resource_name}##{name}"
    end

    # Find an Attribute
    def self.find_by(attributes)
      all.find_by attributes
    end

    # Returns the localized attribute name ("Nom", "Name", "Transporteur", etc)
    def human_name
      # Do not store the value (depend on the current locale)
      I18n.translate! name, scope: ['model_attribute', resource_name]
    rescue I18n::MissingTranslationData
      model_class.human_attribute_name(name)
    end

    def ==(other)
      other && code == other.code
    end

    def initialize(model_class, name)
      @model_class = model_class
      @name = name
    end

    def match_model?(model)
      [model_class, model_name, resource_name].map(&:to_s).include?(model.to_s)
    end

    def self.for(*model_classes, &block)
      empty.for(*model_classes, &block)
    end

    class Collection
      include Enumerable

      def initialize(attributes = [], &block)
        @attributes = attributes
        instance_eval(&block) if block_given?
        freeze
      end

      attr_reader :attributes

      def each(&block)
        attributes.each(&block)
      end

      def define(model_class, name)
        add Chouette::ModelAttribute.new(model_class, name)
      end

      def add(attribute)
        attributes << attribute
      end

      def for(*model_classes, &block)
        model_classes = model_classes.flatten

        attributes = self.attributes.select do |attribute|
          model_classes.any? do |model_class|
            attribute.match_model?(model_class)
          end
        end

        Collection.new(attributes, &block)
      end

      def exclude(model_class, name)
        name = name.to_sym

        attributes.delete_if do |attribute|
          attribute.match_model?(model_class) && attribute.name == name
        end
      end

      def all # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
        # Chouette::StopArea
        define Chouette::StopArea, :name
        define Chouette::StopArea, :parent
        define Chouette::StopArea, :referent
        define Chouette::StopArea, :coordinates
        define Chouette::StopArea, :country_code
        define Chouette::StopArea, :street_name
        define Chouette::StopArea, :zip_code
        define Chouette::StopArea, :city_name
        define Chouette::StopArea, :url
        define Chouette::StopArea, :time_zone
        define Chouette::StopArea, :waiting_time
        define Chouette::StopArea, :postal_region
        define Chouette::StopArea, :status
        define Chouette::StopArea, :registration_number
        define Chouette::StopArea, :public_code
        define Chouette::StopArea, :fare_code
        define Chouette::StopArea, :compass_bearing
        define Chouette::StopArea, :accessibility_limitation_description
        define Chouette::StopArea, :mobility_impaired_accessibility
        define Chouette::StopArea, :wheelchair_accessibility
        define Chouette::StopArea, :step_free_accessibility
        define Chouette::StopArea, :escalator_free_accessibility
        define Chouette::StopArea, :lift_free_accessibility
        define Chouette::StopArea, :audible_signals_availability
        define Chouette::StopArea, :visual_signs_availability

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
        define Chouette::Line, :transport_mode
        define Chouette::Line, :transport_submode
        define Chouette::Line, :url

        # Chouette::JourneyPattern
        define Chouette::JourneyPattern, :name
        define Chouette::JourneyPattern, :published_name

        # Chouette::VehicleJourney
        define Chouette::VehicleJourney, :published_journey_name
        define Chouette::VehicleJourney, :transport_mode
        define Chouette::VehicleJourney, :published_journey_identifier

        self
      end

      def find_by(attributes)
        find do |model_attribute|
          attributes.all? do |k, v|
            model_attribute.send(k).to_s == v.to_s
          end
        end
      end
    end

    def self.empty(&block)
      Collection.new [], &block
    end
  end
end
