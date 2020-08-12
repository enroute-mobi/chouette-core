module Types
	class CompanyType < Types::BaseObject
		description "A Chouette Company"

		field :objectid, String, null: false
		field :name, String, null: true
	end
end