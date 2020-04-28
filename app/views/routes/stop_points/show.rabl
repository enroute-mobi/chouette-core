attributes id: :stoppoint_id
attributes stop_area_id: :stoparea_id
node(:stop_area_referential_id) { |sp| sp.stop_area.stop_area_referential_id }
node(:stoparea_kind) { |sp| sp.stop_area.kind }
node(:user_objectid) { |sp| sp.stop_area.local_id }
node(:short_name) { |sp| sp.stop_area&.name&.truncate(30)&.gsub("&#39;", "'") || '' }
node(:area_type) { |sp| sp.stop_area.area_type }
node(:index) { |sp| sp.position }
node(:edit) { false }
node(:city_name) { |sp| sp.stop_area&.city_name&.gsub("&#39;", "'") || '' }
node(:zip_code) { |sp| sp.stop_area.zip_code }
node(:name) { |sp| sp&.stop_area&.name&.gsub("&#39;", "'") || '' }
node(:registration_number) { |sp| sp.stop_area.registration_number }
node(:text) do |sp|
  fancy_text = sp&.stop_area&.name.gsub("&#39;", "'")
  if sp.stop_area.zip_code && sp.stop_area.city_name
    fancy_text += ", " + sp.stop_area.zip_code + " " + sp.stop_area.city_name.gsub("&#39;", "'")
  end
  fancy_text
end

attributes :for_boarding
attributes :for_alighting
node(:longitude) { |sp| sp.stop_area.longitude || 0 }
node(:latitude) { |sp| sp.stop_area.latitude || 0 }
node(:comment) { |sp| sp.stop_area&.comment&.gsub("&#39;", "'") }
node(:olMap) {{
  isOpened: false,
  json: {}
}}