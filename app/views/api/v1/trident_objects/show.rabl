attributes :objectid => :object_id
[ :object_version, :created_at, :updated_at].each do |attr|
  attributes attr, :unless => lambda { |m| m.send( attr).nil?}
end
node { |model| {short_id: model.get_objectid.short_id} }