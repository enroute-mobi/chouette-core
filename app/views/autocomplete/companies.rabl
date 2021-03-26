collection @companies

node do |company|
  {
    id: company.id,
    text: company.display_name
  }
end
