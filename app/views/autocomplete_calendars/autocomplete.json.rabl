collection @calendars, :object_root => false
attribute :id, :name, :shared

node :text do |cal|
  "<strong>" + cal.name + " - " + cal.id.to_s + "</strong>"
end
