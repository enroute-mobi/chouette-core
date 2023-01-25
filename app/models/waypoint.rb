class Waypoint < ApplicationModel
  belongs_to :shape, required: true
  belongs_to :stop_area, class_name: 'Chouette::StopArea'

  validates_presence_of :coordinates, :position, :waypoint_type
  validates_uniqueness_of :position, scope: :shape_id
  validates_inclusion_of :waypoint_type, in: %w[waypoint constraint]
  validates_length_of :coordinates, is: 2
  validate :presence_of_stop_area

  def longitude
    coordinates&.first
  end

  def latitude
    coordinates&.second
  end

  def self.rgeo_factory
    RGeo::Geos.factory srid: 4326
  end

  def point
    self.class.rgeo_factory.point longitude, latitude
  end

  private

  def presence_of_stop_area
    errors.add(:stop_area, :invalid) if waypoint_type == 'waypoint' && stop_area.blank?
  end
end
