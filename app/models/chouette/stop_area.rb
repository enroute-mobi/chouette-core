require 'geokit'
require 'geo_ruby'
module Chouette
  class StopArea < Chouette::ActiveRecord
    include StopAreaReferentialSupport

    has_metadata
    include ProjectionFields
    include ObjectidSupport
    include CustomFieldsSupport
    include CodeSupport
    include ReferentSupport
    include Documentable

    extend Enumerize
    enumerize :area_type, in: Chouette::AreaType::ALL, default: Chouette::AreaType::COMMERCIAL.first, scope: true
    enumerize :status, in: %i[in_creation confirmed deactivated], default: :in_creation, scope: true
    enumerize :kind, in: %i(commercial non_commercial), default: :commercial
    enumerize :mobility_impaired_accessibility, in: %i(unknown yes no partial), default: :unknown
    enumerize :wheelchair_accessibility, in: %i(unknown yes no partial), default: :unknown
    enumerize :step_free_accessibility, in: %i(unknown yes no partial), default: :unknown
    enumerize :escalator_free_accessibility, in: %i(unknown yes no partial), default: :unknown
    enumerize :lift_free_accessibility, in: %i(unknown yes no partial), default: :unknown
    enumerize :audible_signals_availability, in: %i(unknown yes no partial), default: :unknown
    enumerize :visual_signs_availability, in: %i(unknown yes no partial), default: :unknown

    AVAILABLE_LOCALIZATIONS = %i(en_UK nl_NL de_DE fr_FR it_IT es_ES)

    # WARNING Only effective in the current Referential
    has_many :stop_points
    has_many :routes, through: :stop_points
    has_many :lines, -> { distinct }, through: :routes
    has_many :specific_vehicle_journey_at_stops, :class_name => 'Chouette::VehicleJourneyAtStop', :foreign_key => "stop_area_id"
    has_many :specific_vehicle_journeys, through: :specific_vehicle_journey_at_stops, class_name: 'Chouette::VehicleJourney', source: :vehicle_journey
    has_many :entrances, dependent: :delete_all
    has_many :macro_messages, as: :source, class_name: "::Macro::Message", foreign_key: :source_id

    has_many :stop_area_zones, class_name: 'Fare::StopAreaZone', dependent: :delete_all
    has_many :fare_zones, through: :stop_area_zones, source: :zone

    scope :light, ->{ select(:id, :name, :city_name, :zip_code, :time_zone, :registration_number, :kind, :area_type, :time_zone, :stop_area_referential_id, :objectid) }
    scope :with_time_zone, -> { where.not time_zone: nil }

    scope :by_text, ->(text) { text.blank? ? all : where('lower(stop_areas.name) LIKE :t or lower(stop_areas.objectid) LIKE :t', t: "%#{text.downcase}%") }
    scope :without_compass_bearing, -> { where compass_bearing: nil }
    scope :with_compass_bearing, -> { where.not compass_bearing: nil }
    scope :without_address, -> { where country_code: nil,  street_name: nil, zip_code: nil, city_name: nil }
    scope :without_position, -> { where 'latitude is null or longitude is null' }
    scope :with_position, -> { where 'latitude is not null and longitude is not null' }

    # DEPRECATED Use without/with_positon
    scope :without_geometry, -> { without_position }
    scope :with_geometry, -> { with_position }

    # DEPRECATED. Use particulars relation
    def specific_stops
      particulars
    end

    acts_as_tree :foreign_key => 'parent_id', :order => "name"

    belongs_to_array_in_many :line_routing_constraint_zones, class_name: "LineRoutingConstraintZone", array_name: :stop_areas

    attribute :transport_mode, Chouette::TransportMode::Type.new

    attr_accessor :stop_area_type
    attr_accessor :children_ids
    attr_writer :coordinates

    after_update :journey_patterns_control_route_sections,
                if: Proc.new { |stop_area| ['boarding_position', 'quay'].include? stop_area.stop_area_type }

    validates_presence_of :name
    validates_presence_of :kind
    validates_presence_of :latitude, :if => :longitude
    validates_presence_of :longitude, :if => :latitude
    validates_numericality_of :latitude, :less_than_or_equal_to => 90, :greater_than_or_equal_to => -90, :allow_nil => true
    validates_numericality_of :longitude, :less_than_or_equal_to => 180, :greater_than_or_equal_to => -180, :allow_nil => true
    validates_numericality_of :compass_bearing, :less_than => 360, :greater_than_or_equal_to => 0, :allow_nil => true

    validates_format_of :coordinates, :with => %r{\A *-?(0?[0-9](\.[0-9]*)?|[0-8][0-9](\.[0-9]*)?|90(\.[0]*)?) *\, *-?(0?[0-9]?[0-9](\.[0-9]*)?|1[0-7][0-9](\.[0-9]*)?|180(\.[0]*)?) *\Z}, allow_nil: true, allow_blank: true

    validates_numericality_of :waiting_time, greater_than_or_equal_to: 0, only_integer: true, if: :waiting_time
    validates :time_zone, inclusion: { in: TZInfo::Timezone.all_identifiers }, allow_nil: true, allow_blank: true
    validate :parent_area_type_must_be_greater
    validate :parent_kind_must_be_the_same
    validate :area_type_of_right_kind
    validate :registration_number_is_set
    validates_absence_of :parent_id, message: I18n.t('stop_areas.errors.parent_id.must_be_absent'), if: Proc.new { |stop_area| stop_area.kind == 'non_commercial' }

    validates :registration_number, uniqueness: { scope: :stop_area_provider_id }, allow_blank: true

    before_validation do
      unless self.registration_number.present?
        self.registration_number = stop_area_referential&.generate_registration_number
      end
    end

    def self.nullable_attributes # rubocop:disable Metrics/MethodLength
      %i[
        accessibility_limitation_description
        city_name
        comment
        country_code
        long_lat_type
        nearest_topic_name
        postal_region
        public_code
        registration_number
        street_name
        time_zone
        url
        zip_code
      ]
    end

    def localized_names
      read_attribute(:localized_names) || {}
    end

    def parent_area_type_must_be_greater
      return unless self.parent && has_valid_area_type?

      parent_area_type = Chouette::AreaType.find(self.parent.area_type)
      if Chouette::AreaType.find(self.area_type) >= parent_area_type
        errors.add(:parent_id, I18n.t('stop_areas.errors.parent_area_type', area_type: parent_area_type.label))
      end
    end

    def parent_kind_must_be_the_same
      return unless self.parent

      unless kind == self.parent.kind
        errors.add(:parent_id, I18n.t('stop_areas.errors.parent_kind', kind: kind))
      end
    end

    def has_valid_area_type?
      kind.present? && area_type.present? && Chouette::AreaType.send(self.kind).map(&:to_s).include?(self.area_type)
    end

    def area_type_of_right_kind
      return unless self.kind
      unless has_valid_area_type?
        errors.add(:area_type, I18n.t('stop_areas.errors.incorrect_kind_area_type'))
      end
    end

    def registration_number_is_set
      return unless stop_area_referential&.registration_number_format.present?

      unless registration_number.present?
        errors.add(:registration_number, I18n.t('stop_areas.errors.registration_number.cannot_be_empty'))
      end

      unless stop_area_referential.validates_registration_number(registration_number)
        errors.add(:registration_number, I18n.t('stop_areas.errors.registration_number.invalid', mask: stop_area_referential.registration_number_format))
      end
    end

    before_save :coordinates_to_lat_lng

    def combine_lat_lng
      if self.latitude.nil? || self.longitude.nil?
        ""
      else
        self.latitude.to_s+","+self.longitude.to_s
      end
    end

    def coordinates
      @coordinates || combine_lat_lng
    end

    def coordinates_to_lat_lng
      return unless @coordinates

      if @coordinates.empty?
        self.latitude = self.longitude = nil
      else
        self.latitude, self.longitude = @coordinates.split(",").map(&:to_f)
      end
    end

    def full_name
      "#{name} #{zip_code} #{city_name} - #{local_id}"
    end

    def full_display_name
      [self.get_objectid.short_id, name, zip_code, city_name].compact.join(' - ')
    end

    def display_name
      full_display_name.truncate(50)
    end

    def local_id
      get_objectid.short_id
    end

    def children_in_depth
      return [] if self.children.empty?

      self.children + self.children.map do |child|
        child.children_in_depth
      end.flatten.compact
    end

    def possible_children
      case area_type
        when "BoardingPosition" then []
        when "Quay" then []
        when "CommercialStopPoint" then Chouette::StopArea.where(:area_type => ['Quay', 'BoardingPosition']) - [self]
        when "StopPlace" then Chouette::StopArea.where(:area_type => ['StopPlace', 'CommercialStopPoint']) - [self]
      end
    end

    def possible_parents
      case area_type
        when "BoardingPosition" then Chouette::StopArea.where(:area_type => "CommercialStopPoint")  - [self]
        when "Quay" then Chouette::StopArea.where(:area_type => "CommercialStopPoint") - [self]
        when "CommercialStopPoint" then Chouette::StopArea.where(:area_type => "StopPlace") - [self]
        when "StopPlace" then Chouette::StopArea.where(:area_type => "StopPlace") - [self]
      end
    end

    def geometry_presenter
      Chouette::Geometry::StopAreaPresenter.new self
    end

    def self.commercial
      where kind: "commercial"
    end

    def self.non_commercial
      where kind: "non_commercial"
    end

    def self.stop_place
      where :area_type => "StopPlace"
    end

    def self.physical
      where :area_type => [ "BoardingPosition", "Quay" ]
    end

    def quay?
      area_type&.to_sym == Chouette::AreaType::QUAY
    end

    def to_lat_lng
      Geokit::LatLng.new(latitude, longitude) if latitude and longitude
    end

    def candidate_transport_modes
      Chouette::TransportMode.tree(locale: I18n.locale)
    end

    def closest_children
      return self.children if position.blank?

      parent_point = self.class.connection.quote("SRID=4326;POINT(#{longitude} #{latitude})")
      child_point   = "ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)"

      stop_area_referential.stop_areas.where(parent_id: self.id).order("distance").select('stop_areas.*', "ST_DistanceSphere(#{parent_point}, #{child_point}) as distance")
    end

    def closest_specific_stops
      return self.specific_stops if position.blank?

      parent_point = self.class.connection.quote("SRID=4326;POINT(#{longitude} #{latitude})")
      specific_point   = "ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)"

      stop_area_referential.stop_areas.where(referent_id: self.id).order("distance").select('stop_areas.*', "ST_DistanceSphere(#{parent_point}, #{specific_point}) as distance")
    end

    def geometry
      GeoRuby::SimpleFeatures::Point.from_lon_lat(longitude, latitude, 4326) if latitude and longitude
    end

    def geometry=(geometry)
      geometry = geometry.to_wgs84
      self.latitude, self.longitude, self.long_lat_type = geometry.lat, geometry.lng, "WGS84"
    end

    def position
      geometry
    end

    def position=(position)
      position = nil if String === position && position == ""
      position = Geokit::LatLng.normalize(position), 4326 if String === position
      if position
        self.latitude  = position.lat
        self.longitude = position.lng
      end
    end

    def default_position
      # for first StopArea ... the bounds is nil :(
      Chouette::StopArea.bounds ? Chouette::StopArea.bounds.center : nil # FIXME #821 stop_area_referential.envelope.center
    end

    def around(scope, distance)
      db   = "ST_GeomFromEWKB(ST_MakePoint(longitude, latitude, 4326))"
      from = "ST_GeomFromText('POINT(#{self.longitude} #{self.latitude})', 4326)"
      scope.where("ST_DWithin(#{db}, #{from}, ?, false)", distance)
    end

    def self.near(origin, distance = 0.3)
      origin = origin.to_lat_lng

      lat_degree_units = units_per_latitude_degree(:kms)
      lng_degree_units = units_per_longitude_degree(origin.lat, :kms)

      where "SQRT(POW(#{lat_degree_units}*(#{origin.lat}-latitude),2)+POW(#{lng_degree_units}*(#{origin.lng}-longitude),2)) <= #{distance}"
    end

    def self.bounds
      # Give something like :
      # [["113.5292500000000000", "22.1127580000000000", "113.5819330000000000", "22.2157050000000000"]]
      min_and_max = connection.select_rows("select min(longitude) as min_lon, min(latitude) as min_lat, max(longitude) as max_lon, max(latitude) as max_lat from #{table_name} where latitude is not null and longitude is not null").first
      return nil unless min_and_max

      # Ignore [nil, nil, nil, nil]
      min_and_max.compact!
      return nil unless min_and_max.size == 4

      min_and_max.collect! { |n| n.to_f }

      # We need something like :
      # [[113.5292500000000000, 22.1127580000000000], [113.5819330000000000, 22.2157050000000000]]
      coordinates = min_and_max.each_slice(2).to_a
      GeoRuby::SimpleFeatures::Envelope.from_coordinates coordinates
    end

    # DEPRECATED use StopArea#area_type
    def stop_area_type
      area_type ? area_type : " "
    end

    # DEPRECATED use StopArea#area_type
    def stop_area_type=(stop_area_type)
      self.area_type = (stop_area_type ? stop_area_type.camelcase : nil)
    end

    def children_ids=(children_ids)
      children = children_ids.split(',').uniq
      # remove unset children
      self.children.each do |child|
        if (! children.include? child.id)
          child.update_attribute :parent_id, nil
        end
      end
      # add new children
      Chouette::StopArea.find(children).each do |child|
        child.update_attribute :parent_id, self.id
      end
    end

    def self.default_geometry!
      count = 0
      where(nil).find_each do |stop_area|
        Chouette::StopArea.unscoped do
          count += 1 if stop_area.default_geometry!
        end
      end
      count
    end

    def default_geometry!
      new_geometry = default_geometry
      update_attribute :geometry, new_geometry if new_geometry
    end

    def default_geometry
      children_geometries = children.with_geometry.map(&:geometry).uniq
      GeoRuby::SimpleFeatures::Point.centroid children_geometries if children_geometries.present?
    end

    def children_at_base
      list = Array.new
      children_in_depth.each do |child|
        if child.area_type == 'Quay' || child.area_type == 'BoardingPosition'
          list << child
        end
      end
      list
    end

    def parents
      list = Array.new
      if !parent.nil?
        list << parent
        list += parent.parents
      end
      list
    end

    def duplicate
      sa = self.deep_clone :except => [:object_version, :parent_id, :registration_number]
      sa.uniq_objectid
      sa.name = I18n.t("activerecord.copy", :name => self.name)
      sa
    end

    def journey_patterns_control_route_sections
      if self.changed_attributes['latitude'] || self.changed_attributes['longitude']
        self.stop_points.each do |stop_point|
          stop_point.route.journey_patterns.completed.map{ |jp| jp.control! }
        end
      end
    end

    def self.ransackable_scopes(auth_object = nil)
      [:by_status]
    end

    def self.by_status(*statuses)
      return Chouette::StopArea.all if statuses.reject(&:blank?).length == 3 || statuses.reject(&:blank?).empty?

      status = {
        in_creation: statuses.include?('in_creation'),
        confirmed: statuses.include?('confirmed'),
        deactivated: statuses.include?('deactivated'),
      }

      query = []
      query << "deleted_at IS NOT NULL" if statuses.include?('deactivated')
      query << "(confirmed_at IS NULL AND deleted_at IS NULL)" if statuses.include?('in_creation')
      query << "(confirmed_at IS NOT NULL AND deleted_at IS NULL)" if statuses.include?('confirmed')

      Chouette::StopArea.where(query.join(' OR '))
    end

    def self.order_by_status(dir)
      states = ["confirmed_at #{dir}", "deleted_at #{dir}"]
      states.reverse! if dir == 'asc'
      order(*states)
    end

    def activated?
      !!(deleted_at.nil? && confirmed_at)
    end

    def deactivated?
      deleted_at.present?
    end

    def activate
      self.confirmed_at = Time.now
      self.deleted_at = nil
    end

    def deactivate
      self.deleted_at = Time.now
    end

    def activate!
      update_attribute :confirmed_at, Time.now
      update_attribute :deleted_at, nil
    end

    def deactivate!
      update_attribute :deleted_at, Time.now
    end

    def status
      return :deactivated if deleted_at
      return :confirmed if confirmed_at

      :in_creation
    end

    def status=(status)
      case status&.to_sym
      when :deactivated
        deactivate
      when :confirmed
        activate
      when :in_creation
        self.confirmed_at = self.deleted_at = nil
      end
    end

    def self.statuses
      %i{in_creation confirmed deactivated}
    end

    def time_zone_offset
      return 0 unless time_zone.present?
      ActiveSupport::TimeZone[time_zone]&.utc_offset
    end

    def full_time_zone_name
      return unless time_zone.present?
      return unless ActiveSupport::TimeZone[time_zone].present?
      ActiveSupport::TimeZone[time_zone].tzinfo.name
    end

    def country
      return unless country_code
      ISO3166::Country[country_code]
    end

    def country_name
      return unless country
      country.translations[I18n.locale.to_s] || country.name
    end

    def time_zone_formatted_offset
      return nil unless time_zone.present?
      ActiveSupport::TimeZone[time_zone]&.formatted_offset
    end

    def commercial?
      kind == "commercial"
    end

    def non_commercial?
      !commercial?
    end

    def connection_links
      Chouette::ConnectionLink.where('departure_id = :id or arrival_id = :id', id: self.id)
    end

    def self.union(relation1, relation2)
      union_query = "select id from ((#{relation1.select(:id).to_sql}) UNION (#{relation2.select(:id).to_sql})) stop_area_ids"
      where "stop_areas.id IN (#{union_query})"
    end

    def self.all_parents(relation, ignore_mono_parent: false)
      stop_area_parents = joins('JOIN "public"."stop_areas" children on "public"."stop_areas"."id" = children.parent_id').where("children.id" => relation)

      if ignore_mono_parent
        stop_area_parents = stop_area_parents.group(:id).having('count(children.id) > 1')
      end

      stop_area_parents.distinct
    end

    def formatted_area_type
      area_type_label = I18n.t("area_types.label.#{area_type}")
      "<span class='small label label-info label-stoparea'>#{area_type_label}</span>"
    end

    def formatted_selection_details
      out = ""
      out << formatted_area_type if stop_area_referential.stops_selection_displayed_fields['formatted_area_type']
      extra = [name]
      %i(zip_code city_name postal_region country_name local_id).each do |f|
        extra << send(f) if stop_area_referential.stops_selection_displayed_fields[f.to_s]
      end
      out + extra.select(&:present?).join(' - ')
    end

    def address=(address)
      self.country_code = address.country_code
      self.street_name = address.house_number_and_street_name
      self.zip_code = address.post_code
      self.city_name = address.city_name
    end

    class << self
      def compute_bearings(options={})
        query = <<~TEXT
          SELECT
            stop_area_id, AVG(bearing) AS avg_bearing
          FROM (
              SELECT DISTINCT
                stop_area_id,
                Degrees(
                  ST_Azimuth(
                    ST_LineInterpolatePoint(line, (projected_distance - shape_delta  + abs(projected_distance - shape_delta)) / 2),
                    ST_LineInterpolatePoint(line, ((projected_distance + shape_delta + 1) - abs(projected_distance + shape_delta - 1)) / 2))
                  ) AS bearing
              FROM (
                SELECT *,
                  10 / ST_LengthSpheroid(line, 'SPHEROID["WGS 84", 6378137, 298.257223563]') AS shape_delta,
                  ST_LineLocatePoint(line, point) AS projected_distance
                FROM (
                  SELECT DISTINCT
                    journey_patterns.id AS journey_pattern_id,
                    stop_areas.id AS stop_area_id,
                    shapes.id AS shape_id,
                    stop_areas.latitude AS latitude,
                    stop_areas.longitude AS longitude,
                    ST_SetSRID(ST_Point(stop_areas.longitude, stop_areas.latitude), 4326) AS point,
                    shapes.geometry AS line
                  FROM journey_patterns INNER JOIN public.shapes ON public.shapes.id = journey_patterns.shape_id
                  INNER JOIN journey_patterns_stop_points ON journey_patterns_stop_points.journey_pattern_id = journey_patterns.id
                  INNER JOIN stop_points ON stop_points.id = journey_patterns_stop_points.stop_point_id
                  INNER JOIN public.stop_areas ON public.stop_areas.id = stop_points.stop_area_id
                  WHERE stop_areas.id #{options[:stop_area]&.id.present? ? ["=", options[:stop_area].id].join : "IS NOT NULL"}
                  LIMIT #{options[:limit] || 1000}
                  OFFSET #{(options[:limit] || 1000) *  (options[:page] || 1) - (options[:limit] || 1000)}
                ) AS inputs
              ) AS azimuth_points
          ) AS raw_bearings
          GROUP BY stop_area_id
        TEXT
        ::ActiveRecord::Base.connection.execute(query)
      end

      def average_bearings(options={})
        options_ = options.dup
        options_[:limit] = 5000 unless options_[:limit]
        options_[:page] = 1 unless options_[:page]
        options_[:debug_mode] = false

        result = {}
        loop do
          avg_bearings = compute_bearings(options_)
          avg_bearings.each do |h|
            next unless h["avg_bearing"]
            result[h["stop_area_id"]] = result[h["stop_area_id"]].present? ? (result[h["stop_area_id"]] + h["avg_bearing"]) / 2.0 : h["avg_bearing"]
          end
          break if avg_bearings.count < options_[:limit]
          options_[:page] += 1
        end

        return result.each { |k,v| result[k] = v.round(1) }
      end
    end

    def accessibilities
      Accessibilities.new(
        mobility_impaired_accessibility: mobility_impaired_accessibility,
        wheelchair_accessibility: wheelchair_accessibility,
        step_free_accessibility: step_free_accessibility,
        escalator_free_accessibility: escalator_free_accessibility,
        lift_free_accessibility: lift_free_accessibility,
        audible_signals_availability: audible_signals_availability,
        visual_signs_availability: visual_signs_availability,
        accessibility_limitation_description: accessibility_limitation_description
      )
    end

    class Accessibilities
      def initialize(options={})
        options.each { |k, v| send "#{k}=", v }
      end
      attr_accessor :mobility_impaired_accessibility
      attr_accessor :wheelchair_accessibility
      attr_accessor :step_free_accessibility
      attr_accessor :escalator_free_accessibility
      attr_accessor :lift_free_accessibility
      attr_accessor :audible_signals_availability
      attr_accessor :visual_signs_availability
      attr_accessor :accessibility_limitation_description
    end

    def candidate_fare_zones
      stop_area_referential.fare_zones
    end
  end
end
