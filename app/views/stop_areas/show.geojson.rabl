# frozen_string_literal: true

# Consolidated FeatureCollection for Stop Area map layers
# Includes current stop area, parent, siblings, children, referent, particulars (same referent), and ancestors

node(:type) { 'FeatureCollection' }

node(:crs) do
  {
    type: 'name',
    properties: {
      name: 'EPSG:4326'
    }
  }
end

node(:features) do
  s = @stop_area

  features = []

  def as_feature(stop_area, layer)
    return nil unless stop_area&.longitude && stop_area&.latitude

    {
      type: 'Feature',
      geometry: {
        type: 'Point',
        coordinates: [stop_area.longitude.to_f, stop_area.latitude.to_f]
      },
      properties: {
        id: stop_area.id,
        name: stop_area.name,
        objectid: stop_area.objectid,
        layer: layer,
        type: 'stop_area'
      }
    }
  end

  # Current stop area
  features << as_feature(s, 'stop_area')

  # Parent and Siblings (excluding current)
  if s.parent
    features << as_feature(s.parent, 'parent')
    s.parent.children.where.not(id: s.id).find_each do |sib|
      features << as_feature(sib, 'siblings')
    end
  end

  # Children
  s.children.find_each do |child|
    features << as_feature(child, 'children')
  end

  # Referent (if specific)
  if s.referent
    features << as_feature(s.referent, 'referent')
  end

  # Particulars (specific stop areas of the referent)
  if s.is_referent
    s.specific_stops.find_each do |spec|
      features << as_feature(spec, 'particulars')
    end
  end

  features.compact
end
