collection @line_providers

node do |line_provider|
  {
    id: line_provider.id,
    text: line_provider.short_name
  }
end
