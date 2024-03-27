# frozen_string_literal: true

module Chouette
  class ConnectionLink < Chouette::ActiveRecord
    include StopAreaReferentialSupport

    has_metadata
    include ObjectidSupport
    include CustomFieldsSupport

    belongs_to :departure, :class_name => 'Chouette::StopArea'
    belongs_to :arrival, :class_name => 'Chouette::StopArea'

    # validates_presence_of :link_distance, :default_duration, :departure_id, :arrival_id
    validates_presence_of :default_duration, :departure_id, :arrival_id
    validate :different_departure_and_arrival

    def self.nullable_attributes
      [:link_distance, :default_duration, :frequent_traveller_duration, :occasional_traveller_duration,
        :mobility_restricted_traveller_duration, :link_type]
    end

    def self.duration_kinds
      [:default_duration, :frequent_traveller_duration, :occasional_traveller_duration,
        :mobility_restricted_traveller_duration]
    end

    duration_kinds.each do |k|
      define_method "#{k}_in_min" do
        (self[k] || 0)/60
      end

      define_method "#{k}_in_min=" do |val|
        self[k] = val.to_i * 60
      end
    end

    def default_name
      separator = both_ways? ? '<>' : '>'
      "#{departure.name} #{separator} #{arrival.name}"
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
      return 'both_ways' if both_ways
      departure_id == stop_area_id ? 'to' : 'from'
    end

    private

    def different_departure_and_arrival
      if arrival_id == departure_id
        errors.add(:departure_id, I18n.t('connection_links.errors.same_arrival_and_departure'))
        errors.add(:arrival_id, I18n.t('connection_links.errors.same_arrival_and_departure'))
      end
    end
  end
end
