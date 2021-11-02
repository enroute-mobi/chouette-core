class StopAreaProvider < ActiveRecord::Base
  # This before_validation callback needs to be declared before the one in ObjectidSupport, to prevent a crash if referential_identifier doesn't find the related stop area referential
  # I removed the on_create argument, since that callback needs to be fired even on initialize in workbench#create_dependencies
  before_validation :define_stop_area_referential
  include ObjectidSupport

  belongs_to :stop_area_referential
  belongs_to :workbench, required: true

  has_many :stop_areas, class_name: "Chouette::StopArea"
  has_many :connection_links, class_name: "Chouette::ConnectionLink"
  has_many :stop_area_routing_constraints
  has_many :entrances

  scope :by_text, ->(text) { text.blank? ? all : where('lower(stop_area_providers.name) LIKE :t or lower(stop_area_providers.objectid) LIKE :t', t: "%#{text.downcase}%") }

  # TODO Required by Chouette::Sync::Updater::Batch#resolver limitation
  alias_attribute :registration_number, :objectid
  delegate :workgroup, to: :stop_area_referential

  before_destroy :can_destroy?, prepend: true

  validates :name, presence: true

  def used?
    [ stop_areas, connection_links, stop_area_routing_constraints ].any?(&:exists?)
  end

  private

  def define_stop_area_referential
    self.stop_area_referential ||= workbench&.stop_area_referential
  end

  def can_destroy?
    if used?
      self.errors.add(:base, "Can't be destroy because it has at least one stop area")
      throw :abort
    end
  end

end
