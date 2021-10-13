class Waypoint < ApplicationModel
  belongs_to :shape, required: true

  validates_presence_of :coordinates, :position, :waypoint_type
  validates_uniqueness_of :position, scope: :shape_id
  validates_inclusion_of :waypoint_type, in: %w[waypoint constraint]
  validates_length_of :coordinates, is: 2

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
end
