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
      companies: nil,
      not_transport_mode: nil,
      not_transport_modes: [],
      not_company: nil,
      not_companies: nil)
      scope = context[:target_referential].lines

      if company
        scope = scope.joins(:company).where("companies.name ~~* '%#{company}%'")
      elsif companies
        scope = scope.joins(:company).where("companies.name ~* '.*(#{companies.compact.join('|')}).*'")
      end
      if not_company
        scope = scope.joins(:company).where("companies.name !~~* '%#{not_company}%'")
      elsif companies
        scope = scope.joins(:company).where("companies.name !~* '.*(#{not_companies.compact.join('|')}).*'")
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