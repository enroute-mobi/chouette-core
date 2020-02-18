module Types
	class LineType < Types::BaseObject
		description "A Chouette Line"

		field :id, Integer, null: false
		field :objectid, String, null: false

		field :routes, Types::RouteType.connection_type, null: true,
			description: "The Line's Routes"
		def routes
			LazyLoading::Routes.new(context, object.id)
		end

		field :stop_areas, Types::StopAreaType.connection_type, null: true,
			description: "The Line's StopAreas"
		def stop_areas
			LazyLoading::LineStopAreas.new(context, object.id)
		end
	end
end