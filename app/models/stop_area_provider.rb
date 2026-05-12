class StopAreaProvider < ActiveRecord::Base
  # This before_validation callback needs to be declared before the one in ObjectidSupport, to prevent a crash if referential_identifier doesn't find the related stop area referential
  # I removed the on_create argument, since that callback needs to be fired even on initialize in workbench#create_dependencies
  before_validation :define_stop_area_referential
  include ObjectidSupport
  include CodeSupport

  belongs_to :stop_area_referential # TODO: CHOUETTE-3247 optional: true?
  belongs_to :workbench # CHOUETTE-3247 required: true

  has_many :stop_areas, class_name: "Chouette::StopArea"
  has_many :connection_links, class_name: "Chouette::ConnectionLink"
  has_many :stop_area_routing_constraints
  has_many :entrances
  has_many :stop_area_groups, inverse_of: :stop_area_provider

  scope :by_text, ->(text) { text.blank? ? all : where('lower(stop_area_providers.name) LIKE :t or lower(stop_area_providers.objectid) LIKE :t', t: "%#{text.downcase}%") }

  delegate :workgroup, to: :stop_area_referential

  validates :name, presence: true
  validate :allowed_stop_area_types_must_be_valid
  validate :stop_areas_must_match_allowed_types

  def allowed_stop_area_types=(values)
    return super(nil) if values.nil?

    normalized_values = Array(values).reject(&:blank?).map(&:to_s).uniq
    normalized_values = nil if normalized_values.sort == all_stop_area_types.sort

    super(normalized_values)
  end

  def effective_allowed_stop_area_types
    allowed_stop_area_types || all_stop_area_types
  end

  def used?
    [ stop_areas, connection_links, stop_area_routing_constraints, entrances ].any?(&:exists?)
  end

  private

  def define_stop_area_referential
    self.stop_area_referential ||= workbench&.stop_area_referential
  end

  def allowed_stop_area_types_must_be_valid
    return if allowed_stop_area_types.nil?

    invalid_area_types = allowed_stop_area_types - all_stop_area_types
    return if invalid_area_types.empty?

    errors.add(:allowed_stop_area_types, :invalid)
  end

  def stop_areas_must_match_allowed_types
    return if allowed_stop_area_types.nil?

    invalid_stop_area = stop_areas.where.not(area_type: allowed_stop_area_types).first
    return unless invalid_stop_area

    errors.add(
      :allowed_stop_area_types,
      :incompatible_with_stop_areas,
      name: invalid_stop_area.name,
      area_type: Chouette::AreaType.find(invalid_stop_area.area_type)&.label || invalid_stop_area.area_type
    )
  end

  def all_stop_area_types
    @all_stop_area_types ||= Chouette::AreaType::ALL.map(&:to_s)
  end
end
