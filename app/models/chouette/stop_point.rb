module Chouette
  class StopPoint < Chouette::TridentActiveRecord
    has_metadata
    def self.policy_class
      RoutePolicy
    end

    include ForBoardingEnumerations
    include ForAlightingEnumerations
    include ObjectidSupport

    belongs_to :stop_area
    add_light_belongs_to :stop_area

    belongs_to :route, inverse_of: :stop_points
    validates :route, presence: true

    has_many :journey_patterns, through: :route
    has_many :vehicle_journey_at_stops, dependent: :destroy
    has_many :vehicle_journeys, -> { distinct }, through: :vehicle_journey_at_stops

    belongs_to_array_in_many :routing_constraint_zones, class_name: "Chouette::RoutingConstraintZone", array_name: :stop_points

    acts_as_list :scope => :route, top_of_list: 0

    # Uses a custom validation to avoid StopArea model loading. See #8202
    # validates_presence_of :stop_area
    validate :stop_area_id_validation
    def stop_area_id_validation
      unless stop_area_id.present? && Chouette::StopArea.exists?(stop_area_id)
        errors.add(:stop_area_id, I18n.t("stop_areas.errors.empty"))
      end
    end

    scope :default_order, -> { order("position") }
    scope :light, -> { select(:id, :objectid, :stop_area_id, :for_alighting, :for_boarding, :position) }

    scope :commercial, -> { joins(:stop_area).where("stop_areas.kind = ?", "commercial") }
    scope :non_commercial, -> { joins(:stop_area).where("stop_areas.kind = ?", "non_commercial") }

    delegate :name, :registration_number, :kind, :area_type, to: :stop_area_light

    before_destroy :remove_dependent_journey_pattern_stop_points
    before_destroy :destroy_empty_routing_contraint_zones

    def remove_dependent_journey_pattern_stop_points
      route.journey_patterns.each do |jp|
        if jp.stop_point_ids.include?( id)
          jp.stop_point_ids = jp.stop_point_ids - [id]
        end
      end
    end

    def destroy_empty_routing_contraint_zones
      Chouette::RoutingConstraintZone.with_stop_points_containing(self).find_each do |rcz|
        rcz.stop_point_ids = rcz.stop_point_ids - [id]
        if rcz.stop_points.count < 2
          rcz.destroy
        else
          rcz.save
        end
      end
    end

    def duplicate(for_route:, opposite: false)
      keys_for_create = attributes.keys - %w{id objectid created_at updated_at}
      atts_for_create = attributes
        .slice(*keys_for_create)
        .merge('route_id' => for_route.id)
      atts_for_create["position"] = self.route.stop_points.size - atts_for_create["position"] if opposite
      self.class.create!(atts_for_create)
    end

    def local_id
      "local-#{self.referential.id}-#{self.route.line.get_objectid.local_id}-#{self.route.id}-#{self.id}"
    end

    def self.area_candidates
      Chouette::StopArea.where(:area_type => ['Quay', 'BoardingPosition'])
    end

    def self.find_each_light(&block)
      stop_point = Light::StopPoint.new
      each_row do |row|
        stop_point.attributes = row
        block.call stop_point
      end
    end

    module Light
      class StopPoint

        attr_accessor :id, :route_id, :stop_area_id, :objectid, :position, :for_boarding, :for_alighting

        def initialize(attributes = {})
          self.attributes = attributes
          @attributes = attributes
        end
        attr_accessor :attributes

        def attributes=(attributes)
          @id = attributes["id"]
          @route_id = attributes["route_id"]
          @stop_area_id = attributes["stop_area_id"]
          @objectid = attributes["objectid"]
          @position = attributes["position"]
          @for_boarding = attributes["for_boarding"]
          @for_alighting = attributes["for_alighting"]

          @attributes = attributes
        end

        def method_missing(name, *args)
          stringified_name = name.to_s
          if @attributes.has_key?(stringified_name)
            return @attributes[stringified_name]
          end

          super
        end

        def respond_to?(name, *args)
          return true if @attributes.has_key?(name.to_s)
          super
        end
      end
    end
  end
end
