object false
node(:type) { "FeatureCollection" }

child @stop_areas, root: :features, object_root: false do
  node(:type) { "Feature" }
  node :geometry do |s|
    { coordinates: [s.longitude.to_f, s.latitude.to_f], type: "Point" }
  end

  node :properties do |s|
    {
      name: s.name,
      short_name: truncate(s.name, :length => 30) || "",
      city_name: s.city_name,
      area_type: Chouette::AreaType.find(s.area_type).label,
      registration_number: s.registration_number,
      stoparea_id: s.id,
      stoparea_kind: s.kind,
      text: "#{s.name}, #{s.zip_code} #{s.city_name}",
      user_objectid: s.user_objectid,
      zip_code: s.zip_code,
      latitude: s.latitude,
      longitude: s.longitude,
      comment: s.comment
    }
  end
end
