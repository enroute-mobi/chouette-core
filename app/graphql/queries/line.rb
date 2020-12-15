module Queries
  class Line < Queries::BaseQuery
    description 'Find a line'

    argument :objectid, String, required: false
    argument :registration_number, String, required: false
    argument :transport_mode, Types::TransportMode, required: false
    argument :company, String, required: false

    type Types::LineType, null: true

    def resolve(objectid: nil, registration_number: nil, transport_mode: nil, company: nil)
      l = context[:target_referential].lines.joins(:company).where({
        objectid: objectid,
        registration_number: registration_number,
        transport_mode: transport_mode&.downcase
      }.compact)
      l.where("companies.name like #{company}") if company
      l.first
    end
  end
end
