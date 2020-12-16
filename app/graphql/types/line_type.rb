module Types
  class LineType < Types::BaseObject
    description "A Chouette Line"

    field :objectid, String, null: false
    field :name, String, null: true
    field :registration_number, String, null: true
    field :number, String, null: true
    field :published_name, String, null: true
    field :transport_mode, String, null: true
    field :transport_submode, String, null: true
    field :comment, String, null: true
    field :url, String, null: true
    field :color, String, null: true
    field :text_color, String, null: true

    field :deactivated, Boolean, null: true
    field :seasonal, Boolean, null: true

    field :active_from, GraphQL::Types::ISO8601Date, null: true
    field :active_until, GraphQL::Types::ISO8601Date, null: true

    field :created_at, GraphQL::Types::ISO8601DateTime, null: true
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: true

    field :company, Types::CompanyType, null: true
    def company
      LazyLoading::Company.new(context, object.company_id) if object.company_id
    end

    field :network, Types::NetworkType, null: true
    def network
      LazyLoading::Network.new(context, object.network_id) if object.network_id
    end

    field :secondary_companies, Types::CompanyType.connection_type, null: true
    def secondary_companies
      object.secondary_companies.all
    end

    field :routes, Types::RouteType.connection_type, null: true,
    description: "The Line's Routes"
    def routes
      LazyLoading::Routes.new(context, object.id)
    end

    field :stop_areas, Types::StopAreaType.connection_type, null: true,
    description: "The Line's StopAreas"
    def stop_areas
      LazyLoading::LineStopAreas.new(context, object.id)
    end

    field :service_counts, Types::ServiceCountType.connection_type, null: true, max_page_size: 20 do
      argument :from, String, required: false
      argument :to, String, required: false
    end
    # description: "Service Count for Line"
    def service_counts(from: nil, to: nil)
      LazyLoading::ServiceCounts.new(context, object.id, from, to)
    end

    field :service_count, Integer, null: true do
      argument :from, String, required: false
      argument :to, String, required: false
    end
    def service_count(from: nil, to: nil)
      LazyLoading::ServiceCountTotal.new(context, object.id, from, to)
    end

  end
end
