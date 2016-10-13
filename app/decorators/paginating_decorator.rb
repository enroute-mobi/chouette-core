class PaginatingDecorator < Draper::CollectionDecorator
  delegate :current_page,
           :per_page,
           :offset,
           :total_entries,
           :total_pages,
           :out_of_bounds?,
           :limit_value,
           :model_name,
           :total_count
end
