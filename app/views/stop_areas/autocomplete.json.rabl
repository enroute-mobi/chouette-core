collection @stop_areas

node do |stop_area|
  {
    :id                        => stop_area.id,
    :registration_number       => stop_area.registration_number || "",
    :short_registration_number => truncate(stop_area.registration_number, :length => 10) || "",
    :name                      => stop_area.name || "",
    :short_name                => truncate(stop_area.name, :length => 30) || "",
    :zip_code                  => stop_area.zip_code || "",
    :city_name                 => stop_area.city_name || "",
    :short_city_name           => truncate(stop_area.city_name, :length => 15) || "",
    :user_objectid             => stop_area.local_id,
    :longitude                 => stop_area.longitude,
    :latitude                  => stop_area.latitude,
    :area_type                 => stop_area.area_type,
    :comment                   => stop_area.comment,
    :text                      => stop_area.formatted_selection_details,
    :kind                      => stop_area.kind
  }
end
