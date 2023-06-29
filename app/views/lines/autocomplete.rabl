collection @lines

node do |line|
  {
    :id                        => line.id,
    :registration_number       => line.registration_number || "",
    :short_registration_number => truncate(line.registration_number, :length => 10) || "",
    :name                      => line.name || "",
    :text                      => [ line.name || '', truncate(line.registration_number, :length => 10) || '' ].join(' - '),
  }
end
