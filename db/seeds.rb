# coding: utf-8
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)

stif = Organisation.find_or_create_by!(name: "STIF") do |org|
  org.code = 'STIF'
end

stif.users.find_or_create_by!(username: "admin") do |user|
  user.email = 'stif-boiv@af83.com'
  user.password = "secret"
  user.name = "STIF Administrateur"
end

Workbench.find_or_create_by(name: "Gestion de l'offre", organisation: stif)

operator = Organisation.find_or_create_by!(code: 'transporteur-a') do |organisation|
  organisation.name = "Transporteur A"
end

operator.users.find_or_create_by!(username: "transporteur") do |user|
  user.email = 'stif-boiv+transporteur@af83.com'
  user.password = "secret"
  user.name = "Martin Lejeune"
end

stop_area_referential = StopAreaReferential.find_or_create_by(name: "Reflex") do |referential|
  referential.add_member stif, owner: true
  referential.add_member operator
end

10.times do |n|
  stop_area_referential.stop_areas.find_or_create_by name: "Test #{n}", area_type: "Quay", objectid: "StopArea: #{n}"
end

line_referential = LineReferential.find_or_create_by(name: "CodifLigne") do |referential|
  referential.add_member stif, owner: true
  referential.add_member operator
end

LineReferentialSync.find_or_create_by(line_referential: line_referential)
StopAreaReferentialSync.find_or_create_by(stop_area_referential: stop_area_referential)

10.times do |n|
  line_referential.lines.find_or_create_by name: "Test #{n}" do |l|
    l.objectid = "Chouette:Dummy:Line:00" + n.to_s
  end
end


workbench = Workbench.find_or_create_by(name: "Gestion de l'offre", organisation: operator)

[["parissudest201604", "Paris Sud-Est Avril 2016"],
 ["parissudest201605", "Paris Sud-Est Mai 2016"]].each do |slug, name|
  operator.referentials.find_or_create_by!(slug: slug) do |referential|
    referential.name = name
    referential.prefix = slug
    referential.workbench = workbench
    referential.line_referential = line_referential
    referential.stop_area_referential = stop_area_referential
  end
end
