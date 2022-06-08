collection @line_providers

node do |line_provider|
  {
    :id                        => line_provider.id,
    :name                      => line_provider.name || "",
    :short_name                => truncate(line_provider.short_name, :length => 30) || "",
    :text                      => line_provider.name
  }
end
