module Types
  class NetworkType < Types::BaseObject
    description "A Chouette Network"

    field :objectid, String, null: false
    field :name, String, null: true
  end
end