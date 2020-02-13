module Types
	class StopAreaType < Types::BaseObject
		description "A Chouette StopArea"

		field :id, Integer, null: false
		field :objectid, String, null: false
	end
end