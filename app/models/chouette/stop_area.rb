require 'geokit'
require 'geo_ruby'
module Chouette
  class StopArea < Chouette::ActiveRecord
    has_metadata
    include ProjectionFields
    include StopAreaRestrictions
    include StopAreaReferentialSupport
    include ObjectidSupport
    include CustomFieldsSupport

    extend Enumerize
    enumerize :area_type, in: Chouette::AreaType::ALL
    enumerize :kind, in: %i(commercial non_commercial)

    AVAILABLE_LOCALIZATIONS = %i(en_UK nl_NL de_DE fr_FR it_IT es_ES)

    with_options dependent: :destroy do |assoc|
      assoc.has_many :stop_points
      assoc.has_many :access_points
      assoc.has_many :access_links
    end

    scope :light, ->{ select(:id, :name, :city_name, :zip_code, :time_zone, :registration_number, :kind, :area_type, :time_zone, :stop_area_referential_id, :objectid) }
    has_and_belongs_to_many :routing_lines, :class_name => 'Chouette::Line', :foreign_key => "stop_area_id", :association_foreign_key => "line_id", :join_table => "routing_constraints_lines", :order => "lines.number"
    has_and_belongs_to_many :routing_stops, :class_name => 'Chouette::StopArea', :foreign_key => "parent_id", :association_foreign_key => "child_id", :join_table => "stop_areas_stop_areas", :order => "stop_areas.name"
    has_and_belongs_to_many :stop_area_providers

    belongs_to :referent, class_name: 'Chouette::StopArea'
    has_many :specific_stops, class_name: 'Chouette::StopArea', foreign_key: 'referent_id'

    acts_as_tree :foreign_key => 'parent_id', :order => "name"

    attr_accessor :stop_area_type
    attr_accessor :children_ids
    attr_writer :coordinates

    after_update :journey_patterns_control_route_sections,
                if: Proc.new { |stop_area| ['boarding_position', 'quay'].include? stop_area.stop_area_type }

    # validates_format_of :registration_number, :with => %r{\A[\d\w_:\-]+\Z}, :allow_blank => true
    validates_presence_of :name
    validates_presence_of :kind
    validates_presence_of :latitude, :if => :longitude
    validates_presence_of :longitude, :if => :latitude
    validates_numericality_of :latitude, :less_than_or_equal_to => 90, :greater_than_or_equal_to => -90, :allow_nil => true
    validates_numericality_of :longitude, :less_than_or_equal_to => 180, :greater_than_or_equal_to => -180, :allow_nil => true

    validates_format_of :coordinates, :with => %r{\A *-?(0?[0-9](\.[0-9]*)?|[0-8][0-9](\.[0-9]*)?|90(\.[0]*)?) *\, *-?(0?[0-9]?[0-9](\.[0-9]*)?|1[0-7][0-9](\.[0-9]*)?|180(\.[0]*)?) *\Z}, allow_nil: true, allow_blank: true
    # See #9510
    # validates_format_of :url, :with => %r{\Ahttps?:\/\/([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?\Z}, :allow_nil => true, :allow_blank => true

    validates_numericality_of :waiting_time, greater_than_or_equal_to: 0, only_integer: true, if: :waiting_time
    validates :time_zone, inclusion: { in: TZInfo::Timezone.all_country_zone_identifiers }, allow_nil: true, allow_blank: true
    validate :parent_area_type_must_be_greater
    validate :parent_kind_must_be_the_same
    validate :area_type_of_right_kind
    validate :registration_number_is_set
    validates_absence_of :parent_id, message: I18n.t('stop_areas.errors.parent_id.must_be_absent'), if: Proc.new { |stop_area| stop_area.kind == 'non_commercial' }
    validate :valid_referent

    before_validation do
      self.registration_number = self.stop_area_referential.generate_registration_number unless self.registration_number.present?
    end

    def self.nullable_attributes
      [:registration_number, :street_name, :country_code, :fare_code,
      :nearest_topic_name, :comment, :long_lat_type, :zip_code, :city_name, :url, :time_zone]
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
      if stop_area_referential.stop_areas.where(registration_number: registration_number).\
        where.not(id: id).exists?
        errors.add(:registration_number, I18n.t('stop_areas.errors.registration_number.already_taken'))
      end

      unless registration_number.present?
        errors.add(:registration_number, I18n.t('stop_areas.errors.registration_number.cannot_be_empty'))
      end

      unless stop_area_referential.validates_registration_number(registration_number)
        errors.add(:registration_number, I18n.t('stop_areas.errors.registration_number.invalid', mask: stop_area_referential.registration_number_format))
      end
    end

    def valid_referent
      errors.add(:referent_id, I18n.t('stop_areas.errors.referent_id.cannot_be_referent_and_specific')) if self.referent_id? && (self.is_referent || self.specific_stops.count != 0)
    end

    #after_update :clean_invalid_access_links
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
      if ! @coordinates.nil?
        if @coordinates.empty?
          self.latitude = nil
          self.longitude = nil
        else
          self.latitude = BigDecimal.new(@coordinates.split(",").first)
          self.longitude = BigDecimal.new(@coordinates.split(",").last)
        end
        @coordinates = nil
      end
    end

    def full_name
      "#{name} #{zip_code} #{city_name} - #{local_id}"
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

    def lines
      []
    end

    def routes
      []
    end

    def self.commercial
      where kind: "commercial"
    end

    def self.stop_place
      where :area_type => "StopPlace"
    end

    def self.physical
      where :area_type => [ "BoardingPosition", "Quay" ]
    end

    def self.referent_only
      where is_referent: true
    end

    def to_lat_lng
      Geokit::LatLng.new(latitude, longitude) if latitude and longitude
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

    def routing_stop_ids=(routing_stop_ids)
      stops = routing_stop_ids.split(',').uniq
      self.routing_stops.clear
      Chouette::StopArea.find(stops).each do |stop|
        self.routing_stops << stop
      end
    end

    def routing_line_ids=(routing_line_ids)
      lines = routing_line_ids.split(',').uniq
      self.routing_lines.clear
      Chouette::Line.find(lines).each do |line|
        self.routing_lines << line
      end
    end

    def self.without_geometry
      where("latitude is null or longitude is null")
    end

    def self.with_geometry
      where("latitude is not null and longitude is not null")
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

    def generic_access_link_matrix
      matrix = Array.new
      access_points.each do |access_point|
        matrix += access_point.generic_access_link_matrix
      end
      matrix
    end

    def detail_access_link_matrix
      matrix = Array.new
      access_points.each do |access_point|
        matrix += access_point.detail_access_link_matrix
      end
      matrix
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

    def clean_invalid_access_links
      stop_parents = parents
      access_links.each do |link|
        unless stop_parents.include? link.access_point.stop_area
          link.delete
        end
      end
      children.each do |child|
        child.clean_invalid_access_links
      end
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
      country = ISO3166::Country[country_code]
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

    # def full_name
    #   "#{name} #{zip_code} #{city_name} - #{local_id}"
    # end

    def formatted_area_type
      "<span class='small label label-info label-stoparea'>#{I18n.t("area_types.label.#{area_type}")}</span>"
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
  end
end
