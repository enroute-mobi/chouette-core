collection @stop_area_providers

node do |stop_area_provider|
  {
    :id                        => stop_area_provider.id,
    :name                      => stop_area_provider.name || "",
    :short_name                => truncate(stop_area_provider.name, :length => 30) || "",
    :objectid                  => stop_area_provider.objectid,
    :text                      => stop_area_provider.name,
  }
end
