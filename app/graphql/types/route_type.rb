module Types
	class RouteType < Types::BaseObject
		description "A Chouette Route"

		field :id, Integer, null: false
		field :objectid, String, null: false

		field :stop_areas, [Types::StopAreaType], null: false,
			description: "The Route's StopAreas"
	end
end