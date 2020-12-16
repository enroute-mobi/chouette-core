module Queries
  class Lines < Queries::BaseQuery
    description 'Find all lines'

    argument :transport_mode, Types::TransportMode, required: false
    argument :company, String, required: false

    type Types::LineType.connection_type, null: false

    def resolve(transport_mode: nil, company: nil)
      scope = context[:target_referential].lines
      scope = scope.joins(:company).where("companies.name ilike '%#{company}%'") if company
      scope = scope.where({transport_mode: transport_mode.downcase}) if transport_mode
      scope
    end
  end
end