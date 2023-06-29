class ChouetteSchema < GraphQL::Schema
  default_max_page_size 50

  mutation(Types::MutationType)
  query(Types::QueryType)

  # Lazy load
  lazy_resolve(LazyLoading::Routes, :routes)
  lazy_resolve(LazyLoading::LineStopAreas, :stop_areas)
  lazy_resolve(LazyLoading::RouteStopAreas, :stop_areas)
  lazy_resolve(LazyLoading::Lines, :lines)
  lazy_resolve(LazyLoading::ServiceCounts, :service_counts)
  lazy_resolve(LazyLoading::ServiceCountTotal, :service_count)
  lazy_resolve(LazyLoading::StopRelation, :stop_relation)
  lazy_resolve(LazyLoading::Children, :children)
  lazy_resolve(LazyLoading::Company, :company)
  lazy_resolve(LazyLoading::Network, :network)
end
