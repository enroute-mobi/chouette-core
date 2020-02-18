module Types
	class RouteType < Types::BaseObject
		description "A Chouette Route"

		field :id, Integer, null: false
		field :objectid, String, null: false

		field :stop_areas, Types::StopAreaType.connection_type, null: false,
			description: "The Route's StopAreas"
		def stop_areas
			LazyLoading::RouteStopAreas.new(context, object.id)
		end
	end
end