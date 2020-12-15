module Queries
  class Lines < Queries::BaseQuery
    description 'Find all lines'

    argument :transport_mode, Types::TransportMode, required: false
    argument :company, String, required: false

    type Types::LineType.connection_type, null: false

    def resolve(transport_mode: nil, company: nil)
      if company
        context[:target_referential].lines.joins(:company).where({transport_mode: transport_mode&.downcase}.compact).where("companies.name ilike '%#{company}%'")
      else
        context[:target_referential].lines.where({transport_mode: transport_mode&.downcase}.compact)
      end
    end
  end
end