# frozen_string_literal: true

module Chouette
  class Network < Chouette::ActiveRecord
    has_metadata
    include LineReferentialSupport
    include ObjectidSupport
    extend Enumerize

    has_many :lines, dependent: :nullify

    attr_accessor :source_type_name

    enumerize :source_type_name, in: %w(public_and_private_utilities
                                        road_authorities
                                        transit_operator
                                        public_transport
                                        passenger_transport_coordinating_authority
                                        travel_information_service_provider
                                        travel_agency
                                        individual_subject_of_travel_itinerary
                                        other_information)

    validates_presence_of :name

    scope :by_provider, ->(line_provider) { where(line_provider_id: line_provider.id) }

    def self.object_id_key
      "PTNetwork"
    end

    def self.nullable_attributes
      [:source_name, :source_type, :source_identifier, :comment]
    end

    def commercial_stop_areas
      Chouette::StopArea.joins(:children => [:stop_points => [:route => [:line => :network] ] ]).where(:networks => {:id => self.id}).distinct
    end

    def stop_areas
      Chouette::StopArea.joins(:stop_points => [:route => [:line => :network] ]).where(:networks => {:id => self.id})
    end

    def source_type_name
      # return nil if source_type is nil
      source_type && Chouette::SourceType.new( source_type.underscore)
    end

    def source_type_name=(source_type_name)
      self.source_type = (source_type_name ? source_type_name.camelcase : nil)
    end

    @@source_type_names = nil
    def self.source_type_names
      @@source_type_names ||= Chouette::SourceType.all.select do |source_type_name|
        source_type_name.to_i > 0
      end
    end
  end
end
