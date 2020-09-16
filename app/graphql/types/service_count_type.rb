module Types
  class ServiceCountType < Types::BaseObject
    description "Service count"

    field :date, String, GraphQL::Types::ISO8601Date, null: true
    field :count, Integer, null:true

  end
end
