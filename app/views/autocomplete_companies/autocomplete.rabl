collection @companies, :object_root => false
attribute :id, :name

node :text do |company|
  "<strong>" + company.name + " - " + company.id.to_s + "</strong>"
end
