module Queries
  class Lines < Queries::BaseQuery
    description 'Find all lines'

    argument :transport_mode, Types::TransportMode, required: false
    argument :transport_modes, [Types::TransportMode], required: false
    argument :company, String, required: false
    argument :companies, [String], required: false

    argument :not_transport_mode, Types::TransportMode, required: false
    argument :not_transport_modes, [Types::TransportMode], required: false
    argument :not_company, String, required: false
    argument :not_companies, [String], required: false

    type Types::LineType.connection_type, null: false

    def resolve(transport_mode: nil,
      transport_modes: [],
      company: nil,
      companies: [],
      not_transport_mode: nil,
      not_transport_modes: [],
      not_company: nil,
      not_companies: [])
      scope = context[:target_referential].lines

      if company || companies.length > 0
        scope = scope.joins(:company).where(companies: {objectid: (companies << company).compact})
      end
      if not_company || not_companies.length > 0
        scope = scope.joins(:company).where.not(companies: {objectid: (not_companies << not_company).compact})
      end

      if transport_mode || transport_modes.length > 0
        scope = scope.where({transport_mode: (transport_modes << transport_mode).compact.map(&:downcase)})
      end
      if not_transport_mode || not_transport_modes.length > 0
        scope = scope.where.not({transport_mode: (not_transport_modes << not_transport_mode).compact.map(&:downcase)})
      end

      scope
    end
  end
end