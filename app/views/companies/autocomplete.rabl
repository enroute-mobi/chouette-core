collection @companies

node do |company|
  {
    :id                        => company.id,
    :registration_number       => company.registration_number || "",
    :short_registration_number => truncate(company.registration_number, :length => 10) || "",
    :name                      => company.name || "",
    :short_name                => truncate(company.name, :length => 30) || "",
    :text                      => [ company.name || '', truncate(company.registration_number, :length => 10) || '' ].join(' - '),
  }
end
