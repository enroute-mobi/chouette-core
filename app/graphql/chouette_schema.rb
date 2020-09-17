class ChouetteSchema < GraphQL::Schema
  default_max_page_size 50

  mutation(Types::MutationType)
  query(Types::QueryType)

  # Opt in to the new runtime (default in future graphql-ruby versions)
  use GraphQL::Analysis::AST
  use GraphQL::Execution::Interpreter

  # Add built-in connections for pagination
  use GraphQL::Pagination::Connections

  # Lazy load
  lazy_resolve(LazyLoading::Routes, :routes)
  lazy_resolve(LazyLoading::LineStopAreas, :stop_areas)
  lazy_resolve(LazyLoading::RouteStopAreas, :stop_areas)
  lazy_resolve(LazyLoading::Lines, :lines)
  lazy_resolve(LazyLoading::ServiceCounts, :service_counts)
  lazy_resolve(LazyLoading::ServiceCountTotal, :service_count)
end
