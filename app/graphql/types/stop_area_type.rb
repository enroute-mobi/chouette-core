module Types
	class StopAreaType < Types::BaseObject
		description "A Chouette StopArea"

		field :id, Integer, null: false
		field :objectid, String, null: false

		field :lines, Types::LineType.connection_type, null: true,
			description: "The StopArea's Lines"
		def lines
			LazyLoading::Lines.new(context, object.id)
		end
	end
end