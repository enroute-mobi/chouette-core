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
  validate :allowed_stop_area_types_must_be_known
  validate :stop_areas_must_match_allowed_types, if: :allowed_stop_area_types_changed_on_update?, on: :update

  def allowed_stop_area_types=(values)
    super normalized_allowed_stop_area_types(values)
  end

  def effective_allowed_stop_area_types
    allowed_stop_area_types.presence || all_stop_area_types
  end

  def all_stop_area_types
    @all_stop_area_types ||= Chouette::AreaType::ALL.map(&:to_s)
  end

  def used?
    [ stop_areas, connection_links, stop_area_routing_constraints, entrances ].any?(&:exists?)
  end

  private

  def define_stop_area_referential
    self.stop_area_referential ||= workbench&.stop_area_referential
  end

  def normalized_allowed_stop_area_types(values)
    return [] if values.blank?

    values = Array(values).reject(&:blank?).map(&:to_s).uniq
    return [] if values.empty? || values.sort == all_stop_area_types.sort

    values
  end

  def allowed_stop_area_types_must_be_known
    unknown_area_types = allowed_stop_area_types.to_a - all_stop_area_types
    return if unknown_area_types.empty?

    errors.add(:allowed_stop_area_types, :inclusion, value: unknown_area_types.to_sentence)
  end

  def allowed_stop_area_types_changed_on_update?
    allowed_stop_area_types.present? && will_save_change_to_allowed_stop_area_types?
  end

  def stop_areas_must_match_allowed_types
    invalid_stop_area = stop_areas.where.not(area_type: allowed_stop_area_types).first
    return unless invalid_stop_area

    errors.add(
      :allowed_stop_area_types,
      :incompatible_with_stop_areas,
      name: invalid_stop_area.name,
      area_type: Chouette::AreaType.find(invalid_stop_area.area_type).label
    )
  end
end
