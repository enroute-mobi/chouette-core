module Chouette
  class ConnectionLink < Chouette::TridentActiveRecord
    has_metadata
    include ObjectidSupport
    include ConnectionLinkRestrictions
    include StopAreaReferentialSupport

    attr_accessor :connection_link_type

    belongs_to :departure, :class_name => 'Chouette::StopArea'
    belongs_to :arrival, :class_name => 'Chouette::StopArea'

    validates_presence_of :link_distance, :default_duration, :departure_id, :arrival_id

    def self.nullable_attributes
      [:link_distance, :default_duration, :frequent_traveller_duration, :occasional_traveller_duration,
        :mobility_restricted_traveller_duration, :link_type]
    end

    def self.duration_kinds
      [:default_duration, :frequent_traveller_duration, :occasional_traveller_duration,
        :mobility_restricted_traveller_duration]
    end

    def connection_link_type
      link_type && Chouette::ConnectionLinkType.new(link_type.underscore)
    end

    def connection_link_type=(connection_link_type)
      self.link_type = (connection_link_type ? connection_link_type : nil)
    end

    @@connection_link_types = nil
    def self.connection_link_types
      @@connection_link_types ||= Chouette::ConnectionLinkType.all
    end

    def possible_areas
      Chouette::StopArea.where("area_type != 'ITL'")
    end

    def stop_areas
      Chouette::StopArea.where(:id => [self.departure_id,self.arrival_id])
    end

    def geometry
      GeoRuby::SimpleFeatures::LineString.from_points( [ departure.geometry, arrival.geometry], 4326) if departure.geometry and arrival.geometry
    end

    def geometry_presenter
      Chouette::Geometry::ConnectionLinkPresenter.new self
    end

    def associated_stop stop_area_id
      departure_id == stop_area_id ? arrival : departure
    end

    def direction stop_area_id
      return 'both_way' if both_ways
      departure_id == stop_area_id ? 'to' : 'from'
    end
  end
end
