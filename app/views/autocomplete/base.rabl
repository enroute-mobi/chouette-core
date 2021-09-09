collection @collection

node do |object|
  {
    id: object.id,
    text: object.send(locals[:label_method])
  }
end